@TestOn('vm')
library;

import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('network receives upload bytes before the producer closes', () async {
    final first = Completer<void>();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      var bytes = 0;
      try {
        await for (final chunk in request) {
          bytes += chunk.length;
          if (!first.isCompleted) first.complete();
        }
        request.response.write(bytes);
        await request.response.close();
      } catch (_) {
        if (!first.isCompleted) {
          first.completeError(StateError('Upload failed'));
        }
      }
    });
    final js = JsRuntime(
        options: JsRuntimeOptions(
            fetch: JsFetchOptions(
                baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
                timeout: const Duration(seconds: 2))));
    try {
      final result = js.evalAsync('''globalThis.producer=null;
        fetch('/upload',{method:'POST',body:new ReadableStream({start(c){producer=c;c.enqueue(new Uint8Array([1,2,3]))}}),duplex:'half'}).then(r=>r.text())''');
      await first.future.timeout(const Duration(seconds: 1));
      js.execInitScript(
          'producer.enqueue(new Uint8Array([4,5]));producer.close()');
      expect(await result, '5');
    } finally {
      js.dispose();
      await server.close(force: true);
    }
  });
  test(
      'upload stalls obey deadlines and reserve concurrency before network completion',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      try {
        await request.drain<void>();
        await request.response.close();
      } catch (_) {}
    });
    final js = JsRuntime(
        options: JsRuntimeOptions(
            fetch: JsFetchOptions(
                baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
                timeout: const Duration(milliseconds: 80),
                maxConcurrentRequests: 1)));
    try {
      expect(await js.evalAsync('''(async()=>{
        let cancelled=false;
        const first=fetch('/upload',{method:'POST',body:new ReadableStream({cancel(){cancelled=true}}),duplex:'half'}).catch(e=>e.name);
        const second=await fetch('/second').catch(e=>e.name);
        return [await first,second,cancelled];
      })()'''), ['TimeoutError', 'TypeError', true]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(js.statistics.activeRequests, 0);
    } finally {
      js.dispose();
      await server.close(force: true);
    }
  });
  test('multipart parts can be consumed without whole-form aggregation',
      () async {
    final js = JsRuntime(
        options: const JsRuntimeOptions(
            fetch: JsFetchOptions(
                maxBufferedBodyBytes: 64, maxMultipartPartBytes: 256)));
    try {
      expect(
          await js.evalAsync(
              '''(async()=>{const f=new FormData();for(let i=0;i<8;i++)f.append('part'+i,'x'.repeat(128));
        const response=new Response(f);let count=0,size=0;for await(const p of response.formDataParts()){count++;size+=p.value.length}return [count,size,response.bodyUsed];})()'''),
          [8, 1024, true]);
      expect(
          await js.evalAsync(
              '''(async()=>{const f=new FormData();f.append('large','x'.repeat(300));try{for await(const p of new Response(f).formDataParts()){}return false}catch(e){return e.name}})()'''),
          'TypeError');
    } finally {
      js.dispose();
    }
  });
}
