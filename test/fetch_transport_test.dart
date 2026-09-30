@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

class TestTransport implements JsFetchTransport {
  TestTransport(this.handler);
  final Future<JsFetchResponse> Function(JsFetchRequest, JsFetchCancellation)
      handler;
  final requests = <JsFetchRequest>[];
  final tokens = <JsFetchCancellation>[];
  bool closed = false;
  @override
  Future<JsFetchResponse> send(
      JsFetchRequest request, JsFetchCancellation token) {
    requests.add(request);
    tokens.add(token);
    return handler(request, token);
  }

  @override
  void close() {
    closed = true;
  }
}

JsFetchResponse response(String body,
        {int status = 200, List<List<String>> headers = const []}) =>
    JsFetchResponse(
        status: status,
        statusText: 'OK',
        headers: headers,
        body: Stream.value(utf8.encode(body)));

void main() {
  group('fetch transport lifecycle', () {
    test('redirects enforce policy and strip cross-origin authorization',
        () async {
      final transport =
          TestTransport((request, _) async => request.url.host == 'first.test'
              ? response('', status: 307, headers: [
                  ['location', 'https://second.test/end']
                ])
              : response('done'));
      final visited = <String>[];
      final js = JsRuntime(
          options: JsRuntimeOptions(
              fetch: JsFetchOptions(
                  transport: transport,
                  allowRequest: (url) {
                    visited.add(url.host);
                    return true;
                  })));
      try {
        expect(
            await js.evalAsync(
                'fetch("https://first.test/start",{method:"POST",headers:{authorization:"secret"},body:"上线"}).then(r=>r.text())'),
            'done');
        expect(visited, ['first.test', 'second.test']);
        expect(transport.requests.last.method, 'POST');
        expect(transport.requests.last.body, utf8.encode('上线'));
        expect(
            transport.requests.last.headers.any((h) => h[0] == 'authorization'),
            false);
      } finally {
        js.dispose();
      }
      expect(transport.closed, false);
      final denied = JsRuntime(
          options: JsRuntimeOptions(
              fetch: JsFetchOptions(
                  transport: transport,
                  allowRequest: (u) => u.host == 'first.test')));
      try {
        expect(
            await denied.evalAsync(
                'fetch("https://first.test/start").catch(e=>e.name)'),
            'TypeError');
      } finally {
        denied.dispose();
      }
      expect(transport.requests.length, 3);
    });

    test(
        'cancellation reaches a pending connection and ignores late completion',
        () async {
      final pending = Completer<JsFetchResponse>();
      final transport = TestTransport((_, token) => pending.future);
      final js = JsRuntime(
          options: JsRuntimeOptions(
              fetch: JsFetchOptions(
                  transport: transport, maxConcurrentRequests: 1)));
      try {
        expect(
            await js.evalAsync(
                'globalThis.c=new AbortController(); const p=fetch("https://example.test/",{signal:c.signal}).catch(e=>e.name); c.abort(); p'),
            'AbortError');
        expect(transport.tokens.single.isCancelled, true);
        expect(
            await js.evalAsync(
                'fetch("https://example.test/again").catch(e=>e.name)'),
            'TypeError');
        expect(transport.requests.length, 1);
        var bodyCancelled = false;
        final stream = StreamController<List<int>>(onCancel: () {
          bodyCancelled = true;
        });
        pending.complete(JsFetchResponse(
            status: 200, statusText: 'OK', headers: [], body: stream.stream));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(bodyCancelled, true);
        await stream.close();
      } finally {
        js.dispose();
      }
    });

    test('response limits cancel the body subscription', () async {
      var cancelled = false;
      final stream = StreamController<List<int>>(
          onListen: () {},
          onCancel: () {
            cancelled = true;
          });
      final transport = TestTransport((_, __) async => JsFetchResponse(
          status: 200, statusText: 'OK', headers: [], body: stream.stream));
      final js = JsRuntime(
          options: JsRuntimeOptions(
              fetch:
                  JsFetchOptions(transport: transport, maxResponseBytes: 2)));
      try {
        final fetch = js.evalAsync(
            'fetch("https://example.test/").then(r=>r.text()).catch(e=>e.name)');
        stream.add([1, 2, 3]);
        expect(await fetch, 'TypeError');
        expect(cancelled, true);
      } finally {
        js.dispose();
        await stream.close();
      }
    });

    test('disposing one runtime cancels only its requests on shared transport',
        () async {
      final pending = <Completer<JsFetchResponse>>[];
      final transport = TestTransport((_, __) {
        final p = Completer<JsFetchResponse>();
        pending.add(p);
        return p.future;
      });
      final options =
          JsRuntimeOptions(fetch: JsFetchOptions(transport: transport));
      final first = JsRuntime(options: options),
          second = JsRuntime(options: options);
      final a =
          first.evalAsync('fetch("https://example.test/a").then(r=>r.text())');
      final check = expectLater(a, throwsStateError);
      final b =
          second.evalAsync('fetch("https://example.test/b").then(r=>r.text())');
      first.dispose();
      await check;
      expect(transport.tokens[0].isCancelled, true);
      expect(transport.tokens[1].isCancelled, false);
      expect(transport.closed, false);
      pending[0].complete(response('late'));
      pending[1].complete(response('second'));
      try {
        expect(await b, 'second');
      } finally {
        second.dispose();
      }
      expect(transport.closed, false);
    });

    test('body clone, Request consumption and abort after fetch resolution',
        () async {
      final transport = TestTransport((_, __) async => response('hello'));
      final js = JsRuntime(
          options:
              JsRuntimeOptions(fetch: JsFetchOptions(transport: transport)));
      try {
        expect(
            await js.evalAsync(
                '(()=>{const r=new Request("https://example.test/",{method:"POST",body:"x"});const c=r.clone();const p=fetch(r).then(()=>[r.bodyUsed,c.bodyUsed]);return p;})()'),
            [true, false]);
        expect(
            await js.evalAsync(
                '(()=>{const c=new AbortController();return fetch("https://example.test/",{signal:c.signal}).then(async r=>{c.abort();try{await r.text()}catch(e){return e.name}});})()'),
            'AbortError');
        expect(
            await js.evalAsync(
                'new Response(new Uint8Array([239,187,191,0,255])).text()'),
            '\u0000\ufffd');
      } finally {
        js.dispose();
      }
    });
  });
}
