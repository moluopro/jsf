@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  late JsRuntime js;
  setUp(() => js = JsRuntime());
  tearDown(() => js.dispose());

  test('foreign handles are rejected at all consuming boundaries', () async {
    final other = JsRuntime();
    final foreign = other.evalValue('({x: 42})');
    final object = js.evalValue('({})');
    final function = js.evalValue('(v)=>v');
    try {
      expect(() => js.newValue(foreign), throwsArgumentError);
      expect(() => js.setGlobal('foreign', foreign), throwsArgumentError);
      expect(() => js.callValue(function, [foreign]), throwsArgumentError);
      expect(() => js.callValue(foreign), throwsArgumentError);
      expect(() => object.setPropertyValue('x', foreign), throwsArgumentError);
      expect(() => object.setIndexValue(0, foreign), throwsArgumentError);
      expect(() => function.callWithValues([foreign]), throwsArgumentError);
      expect(() => function.callWithValues([], thisValue: foreign),
          throwsArgumentError);
      await expectLater(js.awaitValue(foreign), throwsArgumentError);
      js.registerHandleFunction('foreignCallback', (_) => foreign.duplicate());
      expect(
          js.eval(
              'try { foreignCallback(); false } catch(e) { /different runtime/.test(e.message) }'),
          true);
      expect(other.eval('40+2'), 42);
      expect(js.eval('40+2'), 42);
    } finally {
      foreign.dispose();
      object.dispose();
      function.dispose();
      other.dispose();
    }
  });

  test('callback disposal is a recoverable error', () {
    js.registerFunction('closeRuntime', (_) {
      js.dispose();
      return null;
    });
    expect(
        js.eval(
            'try { closeRuntime(); false } catch(e) { /Cannot dispose/.test(e.message) }'),
        true);
    js.registerHandleFunction('closeHandleRuntime', (_) {
      js.dispose();
      return null;
    });
    expect(
        js.eval(
            'try { closeHandleRuntime(); false } catch(e) { /Cannot dispose/.test(e.message) }'),
        true);
    expect(js.eval('6*7'), 42);
  });

  test('transfer schema preserves business tags and prototype-shaped keys', () {
    for (final tag in [
      'Undefined',
      'DartFuture',
      'DartError',
      'Object',
      'ArrayHole'
    ]) {
      final map = {
        r'$jsf.type': tag,
        'id': 1,
        '__proto__': {'admin': true}
      };
      js.setGlobal('business', map);
      expect(js.eval('business'), map);
      expect(
          js.eval(
              'Object.hasOwn(business,"__proto__") && business.admin === undefined'),
          true);
      expect(js.call('(x)=>x', [map]), map);
    }
    expect(
        js.eval(r'''JSON.parse('{"$jsf.type":"Undefined","__proto__":3}')'''),
        {r'$jsf.type': 'Undefined', '__proto__': 3});
  });

  test('numeric and view snapshots are lossless', () {
    js.setGlobal('integer', int.parse('9007199254740993'));
    expect(js.eval('typeof integer'), 'bigint');
    expect(js.eval('integer'), BigInt.parse('9007199254740993'));
    final array = js.eval('new BigInt64Array([1n, -2n])') as JsTypedArray;
    expect(array.values, [BigInt.one, -BigInt.two]);
    js.setGlobal('array', array);
    expect(js.eval('array[1]'), -BigInt.two);
    final view = js.eval('new DataView(new Uint8Array([9,1,2,8]).buffer,1,2)')
        as JsDataView;
    expect(view.bytes, [1, 2]);
    js.setGlobal('view', view);
    expect(js.eval('view.getUint16(0)'), 258);
    final floats =
        js.eval('new Float64Array([NaN, Infinity, -0])') as JsTypedArray;
    expect((floats.values[0] as double).isNaN, true);
    expect((floats.values[2] as double).isNegative, true);
    js.setGlobal('map', {1: 'number', '1': 'string'});
    expect(js.eval('map instanceof Map && map.size === 2'), true);
    final circular = <Object?>[];
    circular.add(circular);
    expect(() => js.newValue(circular), throwsArgumentError);
  });

  test('errors preserve structured details and callback throws', () async {
    expect(
        () => js.eval('throw new TypeError("bad", {cause: "origin"})'),
        throwsA(isA<JsException>()
            .having((e) => e.name, 'name', 'TypeError')
            .having((e) => e.message, 'message', 'bad')
            .having((e) => e.cause, 'cause', 'origin')
            .having((e) => e.stack, 'stack', contains('<eval>'))));
    js.registerFunction('fail', (_) => throw StateError('sync error'));
    js.registerHandleFunction(
        'failHandle', (_) => throw StateError('handle error'));
    for (final name in ['fail', 'failHandle']) {
      expect(
          js.eval('try {$name(); false} catch(e) {e instanceof Error}'), true);
    }
    await expectLater(
        js.evalAsync('Promise.reject(new RangeError("async error"))'),
        throwsA(
            isA<JsException>().having((e) => e.name, 'name', 'RangeError')));
  });

  test('execution budgets restart per outer call and validate limits',
      () async {
    js.setTimeout(const Duration(milliseconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(js.eval('(()=>{let n=0;for(let i=0;i<10000;i++)n+=i;return n})()'),
        49995000);
    expect(() => js.eval('while(true){}'), throwsA(isA<JsException>()));
    expect(js.eval('6*7'), 42);
    expect(() => js.setTimeout(Duration.zero), throwsArgumentError);
    expect(() => js.setTimeout(const Duration(days: 100)), throwsArgumentError);
    expect(() => js.setMemoryLimit(-1), throwsArgumentError);
    expect(() => js.setMaxStackSize(0), throwsArgumentError);
  });
}
