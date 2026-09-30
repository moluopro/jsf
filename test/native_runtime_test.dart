@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  group('native runtime', () {
    late JsRuntime js;
    setUp(() => js = JsRuntime());
    tearDown(() => js.dispose());

    test('Unicode code units round trip through values, keys and callbacks',
        () async {
      final random = Random(42);
      final strings = [
        '',
        '上线',
        '𠮷🚀e\u0301',
        '\u0000上线\u0000',
        '\ud800',
        '\udc00',
        ...List.generate(
            50,
            (_) => String.fromCharCodes(
                List.generate(20, (_) => random.nextInt(65536))))
      ];
      for (final text in strings) {
        final literal = jsonEncode(text);
        expect(js.eval(literal), text);
        js.setGlobal(text, text);
        final global = js.getGlobalValue(text);
        try {
          expect(global.toDart(), text);
        } finally {
          global.dispose();
        }
        final object = js.newValue({text: text});
        final value = js.newValue(text);
        try {
          object.setPropertyValue(text, value);
          final property = object.getPropertyValue(text);
          try {
            expect(property.toDart(), text);
          } finally {
            property.dispose();
          }
        } finally {
          object.dispose();
          value.dispose();
        }
        js.registerFunction(text, (args) => args.single);
        expect(js.eval('globalThis[$literal]($literal)'), text);
        js.registerHandleFunction(text, (args) => args.single);
        expect(js.eval('globalThis[$literal]($literal)'), text);
        js.registerFunction('asyncEcho', (args) async => args.single);
        expect(await js.evalAsync('asyncEcho($literal)'), text);
      }
    });

    test('NUL keys do not alias shorter keys', () {
      final object = js.evalValue(r'({a:1,"a\u0000b":2})');
      final property = object.getPropertyValue('a\u0000b');
      try {
        expect(property.toDart(), 2);
      } finally {
        property.dispose();
        object.dispose();
      }
    });

    test('raw NUL and multibyte source use their full byte length', () async {
      expect(js.eval('"上\u0000线"'), '上\u0000线');
      js.registerModule('unicode', 'export const text="上\u0000线";');
      expect(
          await js.evalAsync('import("unicode").then(m=>m.text)'), '上\u0000线');
      final module =
          js.loadModuleValue('direct-unicode', 'export const text="上\u0000线";');
      try {
        expect((module.toDart() as Map)['text'], '上\u0000线');
      } finally {
        module.dispose();
      }
      expect(
          () => js.eval('1', filename: 'bad\u0000name'), throwsArgumentError);
      expect(() => js.registerModule('bad\u0000id', ''), throwsArgumentError);
    });

    test('exception messages preserve Unicode and NUL', () {
      expect(
          () => js.eval(r'throw new Error("上\u0000线\uD800")'),
          throwsA(isA<JsException>().having(
              (e) => e.message, 'message', contains('上\u0000线\ud800'))));
    });

    test('ArrayBuffer bridge preserves every byte and empty buffers', () {
      for (final bytes in [
        Uint8List(0),
        Uint8List.fromList(List.generate(256, (i) => i))
      ]) {
        final value = js.newValue(bytes);
        try {
          expect(value.toBytes(), bytes);
          expect(value.toDart(), bytes);
        } finally {
          value.dispose();
        }
      }
      final wrong = js.newValue(42);
      try {
        expect(wrong.toBytes, throwsA(isA<JsException>()));
      } finally {
        wrong.dispose();
      }
    });

    test(
        'ArrayBuffer copies sliced input and survives transfer and handle release',
        () {
      final input = Uint8List.fromList(List.generate(65553, (i) => i & 255));
      final view = Uint8List.sublistView(input, 17);
      final expected = Uint8List.fromList(view);
      final value = js.newValue(view);
      js.setGlobal('buffer', value);
      value.dispose();
      input.fillRange(0, input.length, 0);
      final moved = js.evalValue('buffer.transfer().transfer(65539)');
      try {
        expect(js.eval('buffer.byteLength'), 0);
        final bytes = moved.toBytes();
        expect(bytes.sublist(0, 65536), expected);
        expect(bytes.sublist(65536), [0, 0, 0]);
      } finally {
        moved.dispose();
      }
    });

    test(
        'ArrayBuffer allocation respects the runtime memory limit and recovers',
        () {
      js.setMemoryLimit(1024 * 1024);
      expect(() {
        final value = js.newValue(Uint8List(4 * 1024 * 1024));
        try {
          value.toBytes();
        } finally {
          value.dispose();
        }
      }, throwsA(isA<JsException>()));
      js.setMemoryLimit(16 * 1024 * 1024);
      final buffer = js.newValue(Uint8List.fromList([0, 128, 255]));
      try {
        expect(buffer.toBytes(), [0, 128, 255]);
      } finally {
        buffer.dispose();
      }
    });

    test('pending promises wake on host events, timeout, and disposal',
        () async {
      js.registerFunction('later', (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 42;
      });
      expect(
          await Future.wait([js.evalAsync('later()'), js.evalAsync('later()')]),
          [42, 42]);
      await expectLater(
          js.evalAsync('new Promise(()=>{})',
              timeout: const Duration(milliseconds: 20)),
          throwsA(isA<JsException>()));
      final pending = js.evalAsync('new Promise(()=>{})');
      final check = expectLater(pending, throwsStateError);
      js.dispose();
      await check;
    });

    test('microtask pump yields to Dart events', () async {
      final future = js.evalAsync(
          'globalThis.stop=false; (async()=>{while(!stop) await Promise.resolve(); return 42;})()');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      js.setGlobal('stop', true);
      expect(await future, 42);
    });

    test(
        'Promise waiting wakes after resolving through a retained function handle',
        () async {
      final promise = js.evalValue(
          'new Promise(resolve=>globalThis.resolveFromHandle=resolve)');
      final resolve = js.getGlobalValue('resolveFromHandle');
      final value = js.newValue('上线');
      try {
        final future =
            js.awaitValue(promise, timeout: const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        resolve.callWithValues([value]).dispose();
        expect(await future, '上线');
      } finally {
        value.dispose();
        resolve.dispose();
        promise.dispose();
      }
    });

    test('fetch is opt-in', () => expect(js.eval('typeof fetch'), 'undefined'));
  });

  group('native fetch', () {
    late HttpServer server;
    late Uri base;
    final runtimes = <JsRuntime>[];
    JsRuntime runtime(
        {Duration timeout = const Duration(seconds: 2),
        int maxResponseBytes = 1024 * 1024,
        int maxRequestBytes = 1024 * 1024,
        int concurrency = 16,
        int redirects = 5}) {
      final js = JsRuntime(
          options: JsRuntimeOptions(
              fetch: JsFetchOptions(
                  baseUrl: base,
                  timeout: timeout,
                  maxResponseBytes: maxResponseBytes,
                  maxRequestBytes: maxRequestBytes,
                  maxConcurrentRequests: concurrency,
                  maxRedirects: redirects)));
      runtimes.add(js);
      return js;
    }

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      server.listen((request) async {
        try {
          final bytes = await request
              .fold<List<int>>([], (all, chunk) => all..addAll(chunk));
          switch (request.uri.path) {
            case '/slow':
              await Future<void>.delayed(const Duration(milliseconds: 250));
              request.response.write('slow');
            case '/binary':
              request.response.add(List.generate(256, (i) => i));
            case '/echo':
              request.response.headers.contentType = ContentType.json;
              request.response.write(jsonEncode({
                'method': request.method,
                'bytes': bytes,
                'contentType': request.headers.value('content-type'),
                'custom': request.headers.value('x-custom')
              }));
            case '/redirect':
              request.response.statusCode = 302;
              request.response.headers.set('location', '/echo');
            case '/loop':
              request.response.statusCode = 307;
              request.response.headers.set('location', '/loop');
            case '/empty':
              request.response.statusCode = 204;
            case '/missing':
              request.response.statusCode = 404;
              request.response.write('missing');
            default:
              request.response.headers.contentType = ContentType.json;
              request.response.write(jsonEncode({'text': '上\u0000线🚀'}));
          }
          await request.response.close();
        } catch (_) {/* Expected when the client aborts an exchange. */}
      });
    });
    tearDown(() async {
      for (final js in runtimes) {
        js.dispose();
      }
      runtimes.clear();
      await server.close(force: true);
    });

    test('GET JSON, status, metadata and body consumption', () async {
      final js = runtime();
      expect(await js.evalAsync('fetch("/").then(r=>r.json()).then(v=>v.text)'),
          '上\u0000线🚀');
      expect(
          await js.evalAsync(
              'fetch("/missing").then(async r=>[r.status,r.ok,await r.text(),r.bodyUsed])'),
          [404, false, 'missing', true]);
      expect(
          await js.evalAsync(
              'fetch("/empty").then(async r=>[r.status,await r.text(),r.bodyUsed])'),
          [204, '', false]);
      expect(
          await js.evalAsync(
              'fetch("/").then(async r=>{await r.text();try{await r.text()}catch(e){return e instanceof TypeError}})'),
          true);
    });
    test('POST text and binary preserve data and headers', () async {
      final js = runtime();
      final text = await js.evalAsync(
              'fetch("/echo",{method:"post",headers:{"X-Custom":"ok"},body:"上线🚀"}).then(r=>r.json())')
          as Map;
      expect(text['method'], 'POST');
      expect(text['bytes'], utf8.encode('上线🚀'));
      expect(text['contentType'], 'text/plain;charset=UTF-8');
      expect(text['custom'], 'ok');
      final binary = await js.evalAsync(
              'fetch("/echo",{method:"POST",body:new Uint8Array([0,128,255])}).then(r=>r.json())')
          as Map;
      expect(binary['bytes'], [0, 128, 255]);
      expect(
          await js.evalAsync(
              'fetch("/binary").then(r=>r.arrayBuffer()).then(b=>Array.from(new Uint8Array(b)))'),
          List.generate(256, (i) => i));
    });
    test('Headers, Request and Response constructors and clone', () async {
      final js = runtime();
      expect(
          js.eval(
              '(()=>{const h=new Headers([["X-A","1"],["x-a","2"]]); return [h.get("X-A"),[...h.keys()]];})()'),
          [
            '1, 2',
            ['x-a']
          ]);
      expect(
          await js.evalAsync(
              'fetch(new Request("/",{headers:{"x-a":"1"}})).then(async r=>{const c=r.clone(); return [await r.text(),await c.text()]})'),
          [
            jsonEncode({'text': '上\u0000线🚀'}),
            jsonEncode({'text': '上\u0000线🚀'})
          ]);
      expect(
          await js
              .evalAsync('Response.json({answer:42}).json().then(v=>v.answer)'),
          42);
      expect(
          await js.evalAsync(
              'fetch("/").then(r=>{try{r.headers.set("a","b")}catch(e){return e instanceof TypeError}})'),
          true);
      expect(
          await js.evalAsync(
              'fetch("/",{method:"GET",body:"x"}).catch(e=>e instanceof TypeError)'),
          true);
      expect(
          await js.evalAsync(
              'fetch("/",{headers:{"x-a":"bad\\r\\nvalue"}}).catch(e=>e instanceof TypeError)'),
          true);
      expect(
          await js.evalAsync(
              'fetch("/",{credentials:"include"}).catch(e=>e instanceof TypeError)'),
          true);
    });
    test('redirect methods, manual response, errors and limits', () async {
      final js = runtime(redirects: 2);
      expect(
          await js.evalAsync(
              'fetch("/redirect",{method:"POST",body:"x"}).then(async r=>[r.redirected,(await r.json()).method])'),
          [true, 'GET']);
      expect(
          await js.evalAsync(
              'fetch("/redirect",{redirect:"manual"}).then(r=>[r.type,r.status])'),
          ['opaqueredirect', 0]);
      expect(
          await js.evalAsync(
              'fetch("/redirect",{redirect:"error"}).catch(e=>e.name)'),
          'TypeError');
      expect(
          await js.evalAsync('fetch("/loop").catch(e=>e.name)'), 'TypeError');
    });
    test('abort preserves reason, deadlines and byte budgets reject', () async {
      final js = runtime(
          timeout: const Duration(milliseconds: 60),
          maxResponseBytes: 100,
          maxRequestBytes: 20);
      expect(
          await js.evalAsync(
              '(()=>{const c=new AbortController(), reason={why:"stop"}; const p=fetch("/slow",{signal:c.signal}).catch(e=>e===reason);c.abort(reason);return p;})()'),
          true);
      expect(await js.evalAsync('fetch("/slow").catch(e=>e.name)'),
          'TimeoutError');
      expect(
          await js.evalAsync(
              'fetch("/binary").then(r=>r.bytes()).catch(e=>e.name)'),
          'TypeError');
      expect(
          await js.evalAsync(
              'fetch("/echo",{method:"POST",body:"x".repeat(21)}).catch(e=>e.name)'),
          'TypeError');
      expect(
          await js.evalAsync(
              'fetch("/",{signal:AbortSignal.abort()}).catch(e=>e.name)'),
          'AbortError');
    });
    test('concurrency budget and disposal do not leave pending Dart waits',
        () async {
      final js = runtime(concurrency: 1);
      expect(
          await js.evalAsync(
              'Promise.all([fetch("/slow").then(r=>r.text()),fetch("/").catch(e=>e.name)])'),
          ['slow', 'TypeError']);
      final pending = js.evalAsync('fetch("/slow")');
      final check = expectLater(pending, throwsStateError);
      js.dispose();
      await check;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });
}
