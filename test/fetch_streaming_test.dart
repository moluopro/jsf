@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';
import 'fetch_transport_test.dart' show TestTransport, response;

void main() {
  group('streaming Fetch', () {
    final runtimes = <JsRuntime>[];
    JsRuntime runtime(JsFetchOptions options) {
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
        'headers resolve before data, demand drives pulls, cancel releases slot',
        () async {
      var produced = 0, cancelled = false;
      Stream<List<int>> source() async* {
        try {
          for (var i = 0; i < 100; i++) {
            produced++;
            yield [i];
          }
        } finally {
          cancelled = true;
        }
      }

      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200, statusText: 'OK', headers: [], body: source()));
      final js = runtime(
          JsFetchOptions(transport: transport, maxConcurrentRequests: 1));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(r=>{globalThis.r=r;return [r.status,r.bodyUsed,r.body instanceof ReadableStream]})'),
          [200, false, true]);
      expect(produced, lessThanOrEqualTo(1));
      expect(
          await js.evalAsync('fetch("https://stream.test/2").catch(e=>e.name)'),
          'TypeError');
      expect(
          await js.evalAsync(
              'globalThis.reader=r.body.getReader();reader.read().then(v=>[...v.value])'),
          [0]);
      expect(produced, lessThanOrEqualTo(2));
      expect(js.eval('r.bodyUsed'), true);
      await js.evalAsync('reader.cancel()');
      expect(cancelled, true);
      expect(
          await js.evalAsync(
              'fetch("https://stream.test/3").then(r=>r.body.cancel()).then(()=>true)'),
          true);
    });

    test(
        'cancelling a body waits for transport cleanup before releasing its slot',
        () async {
      final cleanup = Completer<void>();
      final cancelling = Completer<void>();
      final body = StreamController<List<int>>(onCancel: () {
        cancelling.complete();
        return cleanup.future;
      });
      var calls = 0;
      final transport = TestTransport((_, __) async => ++calls == 1
          ? JsFetchResponse(
              status: 200, statusText: 'OK', headers: [], body: body.stream)
          : response('next'));
      final js = runtime(
          JsFetchOptions(transport: transport, maxConcurrentRequests: 1));
      await js.evalAsync(
          'fetch("https://stream.test").then(r=>{globalThis.r=r;return true})');
      final cancel = js.evalAsync('r.body.cancel().then(()=>true)');
      await cancelling.future;
      expect(
          await js.evalAsync('fetch("https://stream.test").catch(e=>e.name)'),
          'TypeError');
      cleanup.complete();
      expect(await cancel, true);
      expect(
          await js.evalAsync('fetch("https://stream.test").then(r=>r.text())'),
          'next');
      await body.close();
    });

    test('BYOB reader and async iterator preserve binary data and close',
        () async {
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200,
          statusText: 'OK',
          headers: [],
          body: Stream.fromIterable([
            [0, 128, 255],
            [3, 4]
          ])));
      final js = runtime(JsFetchOptions(transport: transport));
      expect(await js.evalAsync('''(async()=>{
        const r=await fetch('https://stream.test'), reader=r.body.getReader({mode:'byob'}), out=[];
        while(true){const x=await reader.read(new Uint8Array(2));if(x.done)break;out.push(...x.value)}
        return [out,r.bodyUsed];
      })()'''), [
        [0, 128, 255, 3, 4],
        true
      ]);
      expect(
          await js.evalAsync(
              '''(async()=>{let a=[];for await(const c of (await fetch('https://stream.test')).body)a.push(...c);return a})()'''),
          [0, 128, 255, 3, 4]);
    });

    test('large incremental response bypasses aggregation budget', () async {
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200,
          statusText: 'OK',
          headers: [],
          body: Stream.fromIterable(
              List.generate(145, (_) => Uint8List(65536)))));
      final js = runtime(
          JsFetchOptions(transport: transport, maxBufferedBodyBytes: 100));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{let n=0;for await(const c of r.body)n+=c.length;return n})'),
          145 * 65536);
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(r=>r.bytes()).catch(e=>[e.name,e.message.includes("Buffered")])'),
          ['TypeError', true]);
    });

    test('abort after headers rejects pending read with identical reason',
        () async {
      var cancelled = false;
      final body = StreamController<List<int>>(onCancel: () {
        cancelled = true;
      });
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200, statusText: 'OK', headers: [], body: body.stream));
      final js = runtime(JsFetchOptions(transport: transport));
      expect(
          await js.evalAsync(
              '''(async()=>{globalThis.c=new AbortController();globalThis.r=await fetch('https://stream.test',{signal:c.signal});const reader=r.body.getReader();const reason={stop:1};const p=reader.read().catch(e=>e===reason);c.abort(reason);return p})()'''),
          true);
      expect(cancelled, true);
      await body.close();
    });

    test('network errors after headers error the body', () async {
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200,
          statusText: 'OK',
          headers: [],
          body: Stream.error(const SocketException('lost'))));
      final js = runtime(JsFetchOptions(transport: transport));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>[r.status,await r.text().catch(e=>e.name)])'),
          [200, 'TypeError']);
    });

    test(
        'idle deadline cancels pending read, absolute deadline errors paused body',
        () async {
      final streams = <StreamController<List<int>>>[];
      final transport = TestTransport((_, __) async {
        final c = StreamController<List<int>>();
        streams.add(c);
        return JsFetchResponse(
            status: 200, statusText: 'OK', headers: [], body: c.stream);
      });
      final js = runtime(JsFetchOptions(
          transport: transport,
          bodyIdleTimeout: const Duration(milliseconds: 40)));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(r=>r.text()).catch(e=>e.name)'),
          'TimeoutError');
      final deadline = runtime(JsFetchOptions(
          transport: transport, timeout: const Duration(milliseconds: 80)));
      await deadline.evalAsync(
          'fetch("https://stream.test").then(r=>{globalThis.r=r;return true})');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(await deadline.evalAsync('r.text().catch(e=>e.name)'),
          'TimeoutError');
      for (final c in streams) {
        await c.close();
      }
    });

    test('consumer pauses do not consume the network idle deadline', () async {
      final transport = TestTransport((_, __) async => response('ready'));
      final js = runtime(JsFetchOptions(
          transport: transport,
          bodyIdleTimeout: const Duration(milliseconds: 30)));
      await js.evalAsync(
          'fetch("https://stream.test").then(r=>{globalThis.r=r;return true})');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(await js.evalAsync('r.text()'), 'ready');
    });

    test('clones consume independently and overflow errors slow branch',
        () async {
      final transport = TestTransport((_, __) async => response('hello'));
      final js =
          runtime(JsFetchOptions(transport: transport, maxCloneBufferBytes: 8));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{const c=r.clone();return [await r.text(),await c.text()]})'),
          ['hello', 'hello']);
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{const c=r.clone();return Promise.all([r.text(),c.text()])})'),
          ['hello', 'hello']);
      final small =
          runtime(JsFetchOptions(transport: transport, maxCloneBufferBytes: 2));
      expect(
          await small.evalAsync(
              'fetch("https://stream.test").then(async r=>{const c=r.clone();const a=await r.text().catch(e=>e.name);return [a,await c.text().catch(e=>e.name)]})'),
          ['TypeError', 'TypeError']);
    });

    test('clone cancellation requires both branches and abort cancels both',
        () async {
      var cancelled = false;
      final controller = StreamController<List<int>>(onCancel: () {
        cancelled = true;
      });
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200, statusText: 'OK', headers: [], body: controller.stream));
      final js = runtime(JsFetchOptions(transport: transport));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{const c=r.clone();await Promise.all([r.body.cancel(),c.body.cancel()]);return true})'),
          true);
      expect(cancelled, true);
      await controller.close();
    });

    test('pipeThrough handles split UTF-8, and reader locks forbid body mixins',
        () async {
      final bytes = utf8.encode('上\u0000线🚀');
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200,
          statusText: 'OK',
          headers: [],
          body: Stream.fromIterable(bytes.map((b) => [b]))));
      final js = runtime(JsFetchOptions(transport: transport));
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{let s="";for await(const c of r.body.pipeThrough(new TextDecoderStream()))s+=c;return s})'),
          '上\u0000线🚀');
      expect(
          await js.evalAsync(
              'fetch("https://stream.test").then(async r=>{const reader=r.body.getReader();const used=r.bodyUsed;const e=await r.text().catch(e=>e.name);reader.releaseLock();return [used,e,await r.text()]})'),
          [false, 'TypeError', '上\u0000线🚀']);
    });

    test('dispose releases a paused body and its borrowed transport stays open',
        () async {
      var cancelled = false;
      final body = StreamController<List<int>>(onCancel: () {
        cancelled = true;
      });
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200, statusText: 'OK', headers: [], body: body.stream));
      final js = runtime(JsFetchOptions(transport: transport));
      await js.evalAsync('fetch("https://stream.test").then(()=>true)');
      js.dispose();
      expect(cancelled, true);
      expect(transport.closed, false);
      await body.close();
    });

    test('real HTTP SSE returns first event before server closes', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final finish = Completer<void>();
      server.listen((req) async {
        try {
          req.response.bufferOutput = false;
          req.response.headers.contentType =
              ContentType('text', 'event-stream', charset: 'utf-8');
          req.response.write('data: 上线\n\n');
          await req.response.flush();
          await finish.future;
          await req.response.close();
        } catch (_) {}
      });
      final js = runtime(JsFetchOptions(
          baseUrl: Uri.parse('http://127.0.0.1:${server.port}')));
      try {
        expect(
            await js.evalAsync(
                'fetch("/").then(async r=>{const reader=r.body.getReader();const first=await reader.read();await reader.cancel();return new TextDecoder().decode(first.value)})'),
            'data: 上线\n\n');
      } finally {
        finish.complete();
        await server.close(force: true);
      }
    });
  });
}
