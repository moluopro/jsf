@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';
import 'fetch_transport_test.dart' show TestTransport, response;

void main() {
  group('Fetch binary and form data', () {
    final runtimes = <JsRuntime>[];
    JsRuntime runtime([JsFetchOptions options = const JsFetchOptions()]) {
      final js = JsRuntime(options: JsRuntimeOptions(fetch: options));
      runtimes.add(js);
      return js;
    }

    tearDown(() {
      for (final js in runtimes) {
        js.dispose();
      }
      runtimes.clear();
    });

    test(
        'Blob snapshots views, slices, normalizes type and supports byte readers',
        () async {
      final js = runtime();
      expect(await js.evalAsync('''(async()=>{
        const a=new Uint8Array([0,128,255,65]); const b=new Blob([a.subarray(1,3),'上线'],{type:'TEXT/PLAIN'});a.fill(9);
        const f=new File([b],'中\\ud800.bin',{lastModified:123,type:'APPLICATION/OCTET-STREAM'});
        const reader=b.stream().getReader({mode:'byob'}), bytes=[];
        while(true){const c=await reader.read(new Uint8Array(3));if(c.done)break;bytes.push(...c.value)}
        return [b.size,b.type,[...await b.slice(0,2).bytes()],await b.slice(2).text(),f.name,f.lastModified,f instanceof Blob,bytes];
      })()'''), [
        8,
        'text/plain',
        [128, 255],
        '上线',
        '中\ufffd.bin',
        123,
        true,
        [128, 255, ...utf8.encode('上线')]
      ]);
      expect(
          await js.evalAsync(
              'new Response(new Blob(["hello"],{type:"TEXT/PLAIN"})).blob().then(async b=>[b.type,await b.text()])'),
          ['text/plain', 'hello']);
    });

    test(
        'FormData preserves repeats, order, File metadata and set/delete semantics',
        () async {
      final js = runtime();
      expect(await js.evalAsync('''(async()=>{
        const f=new FormData(); f.append('a','1');f.append('b','2');f.append('a','3');
        f.append('file',new Blob([new Uint8Array([0,255])],{type:'image/png'}),'上.bin');
        const before=f.getAll('a');f.set('a','4');f.delete('b');
        let bad=false;try{f.append('x','text','file')}catch(e){bad=e instanceof TypeError}
        return [before,[...f.keys()],f.get('a'),f.get('file').name,f.get('file') instanceof File,[...await f.get('file').bytes()],bad];
      })()'''), [
        ['1', '3'],
        ['a', 'file'],
        '4',
        '上.bin',
        true,
        [0, 255],
        true
      ]);
    });

    test('multipart round trip includes Chinese, NUL, binary and empty files',
        () async {
      final js = runtime();
      expect(await js.evalAsync('''(async()=>{
        const f=new FormData();f.append('中文','上\\0线');f.append('repeat','a');f.append('repeat','b');
        f.append('binary',new File([new Uint8Array([0,128,255,13,10])],'文件.bin',{type:'application/octet-stream'}));
        f.append('empty',new Blob([]),'empty.txt');f.append('lines','a\\nb\\rc\\r\\nd');
        const r=new Response(f), clone=r.clone(), parsed=await r.formData();
        return [r.headers.get('content-type').startsWith('multipart/form-data; boundary='),parsed.get('中文'),parsed.getAll('repeat'),
          parsed.get('binary').name,[...await parsed.get('binary').bytes()],parsed.get('empty').size,parsed.get('lines'),(await clone.text()).endsWith('--\\r\\n')];
      })()'''), [
        true,
        '上\u0000线',
        ['a', 'b'],
        '文件.bin',
        [0, 128, 255, 13, 10],
        0,
        'a\r\nb\r\nc\r\nd',
        true
      ]);
    });

    test('multipart escaping cannot inject headers and malformed input rejects',
        () async {
      final js = runtime();
      expect(await js.evalAsync(r'''(async()=>{
        const f=new FormData();f.append('a"\r\nb','text');f.append('file',new Blob(['x']),'x"\r\nInjected: true');
        const text=await new Response(f).text();
        const cases=[
          new Response('bad',{headers:{'content-type':'multipart/form-data'}}),
          new Response('--x\r\nContent-Disposition: form-data; name="a"\r\n\r\nmissing end',{headers:{'content-type':'multipart/form-data; boundary=x'}}),
          new Response('x',{headers:{'content-type':'application/json'}})
        ];
        return [text.includes('%22%0D%0A'),!text.includes('\r\nInjected:'),await Promise.all(cases.map(r=>r.formData().then(()=>false,e=>e instanceof TypeError)))];
      })()'''), [
        true,
        true,
        [true, true, true]
      ]);
    });

    test('multipart MIME parameters and malformed delimiters are checked',
        () async {
      final js = runtime();
      expect(await js.evalAsync(r'''(async()=>{
        const data='--x\r\nContent-Disposition: form-data; name="a"\r\n\r\nvalue\r\n--x--\r\n';
        const form=await new Response(data,{headers:{'content-type':'Multipart/Form-Data; BOUNDARY = "x"'}}).formData();
        const bad=await new Response(data.replace('--x\r\n','--xXX'),{headers:{'content-type':'multipart/form-data; boundary=x'}}).formData().catch(e=>e.name);
        return [form.get('a'),bad,new URLSearchParams(null).toString(),typeof __jsfFetchPlatform,typeof __jsfFetchRead];
      })()'''), ['value', 'TypeError', '', 'undefined', 'undefined']);
    });

    test('URL-encoded forms preserve order, malformed escapes and Unicode',
        () async {
      final js = runtime();
      expect(await js.evalAsync(r'''(async()=>{
        const p=new URLSearchParams([['a','1'],['b','2'],['a','3'],['中','上\0线']]);
        const f=await new Response(p).formData();
        const bad=await new Response('x=%FF%zz&plus=a+b&nul=%00',{headers:{'content-type':'application/x-www-form-urlencoded'}}).formData();
        return [[...p.keys()],f.getAll('a'),f.get('中'),bad.get('x'),bad.get('plus'),bad.get('nul'),new URLSearchParams('a=1&b=2&a=3').toString()];
      })()'''), [
        ['a', 'b', 'a', '中'],
        ['1', '3'],
        '上\u0000线',
        '\ufffd%zz',
        'a b',
        '\u0000',
        'a=1&b=2&a=3'
      ]);
    });

    test('multipart part, header and aggregate limits reject deterministically',
        () async {
      final js = runtime(const JsFetchOptions(
          maxFormDataParts: 2,
          maxMultipartHeaderBytes: 50,
          maxBufferedBodyBytes: 500));
      expect(await js.evalAsync(r'''(async()=>{
        const f=new FormData();f.append('a','1');f.append('b','2');f.append('c','3');
        let many;try{new Response(f)}catch(e){many=e.name}
        const long='--x\r\nContent-Disposition: form-data; name="'+ 'x'.repeat(100)+'"\r\n\r\na\r\n--x--\r\n';
        return [many,await new Response(long,{headers:{'content-type':'multipart/form-data; boundary=x'}}).formData().catch(e=>e.name),await new Response('a'.repeat(501)).bytes().catch(e=>e.name)];
      })()'''), ['TypeError', 'TypeError', 'TypeError']);
    });

    test('UTF-8 streaming decoder handles every split and malformed sequences',
        () async {
      final js = runtime();
      expect(await js.evalAsync(r'''(async()=>{
        const encoded=new TextEncoder().encode('\ufeff上\0线🚀');const splits=[];
        for(let i=0;i<=encoded.length;i++){const d=new TextDecoder();splits.push(d.decode(encoded.slice(0,i),{stream:true})+d.decode(encoded.slice(i)))}
        const d=new TextDecoder();const malformed=d.decode(new Uint8Array([0xe0,0x80,0x61,0xf0,0x9f]),{stream:true})+d.decode();
        const target=new Uint8Array(3), count=new TextEncoder().encodeInto('a🚀',target);
        let fatal;try{new TextDecoder('utf-8',{fatal:true}).decode(new Uint8Array([255]))}catch(e){fatal=e.name}
        let value='';const output=new ReadableStream({start(c){c.enqueue('\ud83d');c.enqueue('\ude80');c.close()}}).pipeThrough(new TextEncoderStream()).pipeThrough(new TextDecoderStream());
        for await(const c of output)value+=c;
        return [splits.every(s=>s==='上\0线🚀'),malformed,count,fatal,value,new TextDecoder('utf-8',{ignoreBOM:true}).decode(encoded).charCodeAt(0)];
      })()'''), [
        true,
        '\ufffd\ufffda\ufffd',
        {'read': 1, 'written': 1},
        'TypeError',
        '🚀',
        65279
      ]);
    });

    test('request clone and stream BodyInit consumption obey locks and budgets',
        () async {
      final transport = TestTransport(
          (request, _) async => response(utf8.decode(request.body!)));
      final js =
          runtime(JsFetchOptions(transport: transport, maxRequestBytes: 10));
      expect(await js.evalAsync('''(async()=>{
        const r=new Request('https://form.test',{method:'POST',body:'hello'}),c=r.clone();
        const result=await fetch(r).then(r=>r.text());
        const stream=new ReadableStream({start(c){c.enqueue(new Uint8Array([97,98]));c.close()}});
        const streamed=await fetch('https://form.test',{method:'POST',body:stream,duplex:'half'}).then(r=>r.text());
        return [result,await c.text(),r.bodyUsed,streamed];
      })()'''), ['hello', 'hello', true, 'ab']);
      expect(
          await js.evalAsync(
              'fetch("https://form.test",{method:"POST",body:new Blob(["x".repeat(11)])}).catch(e=>e.name)'),
          'TypeError');
    });

    test(
        'real HTTP multipart upload and 307 replay preserve bytes and boundary',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = <List<int>>[], types = <String>[];
      server.listen((request) async {
        try {
          final bytes =
              await request.fold<List<int>>([], (a, b) => a..addAll(b));
          received.add(bytes);
          types.add(request.headers.contentType.toString());
          if (request.uri.path == '/redirect') {
            request.response.statusCode = 307;
            request.response.headers.set('location', '/echo');
          } else {
            request.response.headers
                .set('content-type', request.headers.value('content-type')!);
            request.response.add(bytes);
          }
          await request.response.close();
        } catch (_) {}
      });
      final js = runtime(JsFetchOptions(
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}')));
      try {
        expect(
            await js.evalAsync(
                '''(async()=>{const f=new FormData();f.append('text','上线');f.append('file',new File([new Uint8Array([0,128,255])],'文件.bin'));const r=await fetch('/redirect',{method:'POST',body:f});const p=await r.formData();return [r.redirected,p.get('text'),p.get('file').name,[...await p.get('file').bytes()]]})()'''),
            [
              true,
              '上线',
              '文件.bin',
              [0, 128, 255]
            ]);
        expect(received.length, 2);
        expect(received[0], received[1]);
        expect(types[0], types[1]);
      } finally {
        await server.close(force: true);
      }
    });
  });
}
