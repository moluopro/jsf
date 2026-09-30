import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('snapshots preserve binary data, tagged keys and realm constructors',
      () {
    final js = JsRuntime();
    try {
      final bytes = Uint8List.fromList([0, 128, 255]);
      js.setGlobal('bytes', bytes);
      bytes[0] = 99;
      expect(js.eval('bytes instanceof ArrayBuffer'), true);
      expect(js.eval('bytes'), [0, 128, 255]);
      final snapshot = js.eval('bytes') as Uint8List;
      snapshot[0] = 88;
      expect(js.eval('new Uint8Array(bytes)[0]'), 0);
      js.setGlobal('data', {r'$jsf.type': 'DartFuture', '__proto__': 42});
      expect(js.eval('Object.hasOwn(data,"__proto__")'), true);
      expect(js.eval('data'), {r'$jsf.type': 'DartFuture', '__proto__': 42});
      js.setGlobal('values', <Object?>[1, 2]);
      expect(js.eval('values instanceof Array'), true);
      final callback = js.registerFunction('f', (_) => null);
      expect(js.eval('f instanceof Function'), true);
      callback.dispose();
      expect(() => js.eval('f()'), throwsA(isA<JsException>()));
    } finally {
      js.dispose();
    }
  });
  test('scopes release handles after success, failure and async completion',
      () async {
    final js = JsRuntime();
    try {
      final baseline = js.statistics.liveHandles;
      JsValue? retained;
      expect(withJsValues((scope) {
        final value = scope.own(js.evalValue('42'));
        retained = scope.release(scope.own(js.evalValue('7')));
        return value.toDart();
      }), 42);
      expect(js.statistics.liveHandles, baseline + 1);
      retained!.dispose();
      expect(
          () => withJsValues<void>((scope) {
                scope.own(js.evalValue('({})'));
                throw StateError('expected');
              }),
          throwsStateError);
      expect(
          await withJsValuesAsync((scope) async {
            final value = scope.own(js.evalValue('Promise.resolve(42)'));
            return js.awaitValue(value);
          }),
          42);
      expect(js.statistics.liveHandles, baseline);
    } finally {
      js.dispose();
    }
  });
  test('host Future rejection is a JS Error and quota recovers', () async {
    final js = JsRuntime(options: const JsRuntimeOptions(maxPendingFutures: 1));
    final pending = Completer<int>();
    try {
      js.registerFunction('pending', (_) => pending.future);
      js.registerFunction(
          'fail', (_) async => throw StateError('async failure'));
      final value = js.evalValue('pending()');
      expect(js.statistics.pendingFutures, 1);
      expect(js.eval('try{fail();false}catch(e){e.name==="DartError"}'), true);
      pending.complete(42);
      expect(await js.awaitValue(value), 42);
      value.dispose();
      expect(js.statistics.pendingFutures, 0);
      expect(
          await js.evalAsync(
              'fail().catch(e=>[e instanceof Error,e.name,/async failure/.test(e.message)])'),
          [true, 'DartError', true]);
      expect(js.statistics.pendingFutures, 0);
    } finally {
      if (!pending.isCompleted) pending.complete(0);
      js.dispose();
    }
  });
}
