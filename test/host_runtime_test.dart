@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('timers, microtasks and cancellation share the runtime lifecycle',
      () async {
    final js = JsRuntime(options: const JsRuntimeOptions(maxTimers: 4));
    try {
      expect(
          await js.evalAsync(
              'new Promise(resolve=>setTimeout((a,b)=>resolve(a+b),1,20,22))'),
          42);
      expect(
          await js.evalAsync(
              'new Promise(resolve=>{let n=0;const id=setInterval(()=>{if(++n===3){clearInterval(id);resolve(n)}},1)})'),
          3);
      expect(
          await js.evalAsync(
              'new Promise(resolve=>queueMicrotask(()=>resolve(42)))'),
          42);
      js.execInitScript(
          'globalThis.unwanted=0;const id=setTimeout(()=>unwanted++,5);clearTimeout(id)');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(js.eval('unwanted'), 0);
      expect(js.statistics.pendingTimers, 0);
      js.execInitScript('for(let i=0;i<4;i++)setTimeout(()=>{},10000)');
      expect(
          () => js.eval('setTimeout(()=>{},1)'), throwsA(isA<JsException>()));
    } finally {
      js.dispose();
    }
  });
  test('URL parsing and AbortSignal composition are available without Fetch',
      () async {
    final js = JsRuntime();
    try {
      expect(
          js.eval(
              'const u=new URL("../路径?a=1","https://例子.测试/root/item");[u.hostname,u.pathname,u.searchParams.get("a")]'),
          ['xn--fsqu00a.xn--0zwm56d', '/%E8%B7%AF%E5%BE%84', '1']);
      expect(js.eval('u.searchParams.set("a","two words");u.search'),
          '?a=two+words');
      expect(js.eval('AbortSignal.any([AbortSignal.abort(42)]).reason'), 42);
      expect(
          await js.evalAsync(
              'new Promise(resolve=>{const s=AbortSignal.timeout(1);s.addEventListener("abort",()=>resolve(s.reason.name))})'),
          'TimeoutError');
    } finally {
      js.dispose();
    }
  });
  test('diagnostics report structured console and unhandled rejections only',
      () async {
    final console = <JsConsoleEvent>[],
        rejections = <JsException>[],
        errors = <JsException>[];
    final js = JsRuntime(
        options: JsRuntimeOptions(
            onConsole: console.add,
            onUnhandledRejection: rejections.add,
            onError: errors.add));
    try {
      js.execInitScript(
          'console.warn("message",{value:42});Promise.reject(new TypeError("unhandled"));setTimeout(()=>{throw new Error("timer")},1)');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(console.single.level, 'warn');
      expect(console.single.arguments, [
        'message',
        {'value': 42}
      ]);
      expect(rejections.single.name, 'TypeError');
      expect(rejections.single.message, 'unhandled');
      expect(errors.single.message, 'timer');
      await expectLater(js.evalAsync('Promise.reject(new Error("observed"))'),
          throwsA(isA<JsException>()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(rejections.length, 1);
      expect(js.statistics.memoryUsedBytes, greaterThan(0));
      expect(js.capabilities.abiVersion, 2);
    } finally {
      js.dispose();
    }
  });
  test(
      'callback registrations can be replaced and revoked without retaining closures',
      () {
    final js = JsRuntime(options: const JsRuntimeOptions(maxCallbacks: 1));
    try {
      final old = js.registerFunction('callback', (_) => 1);
      js.execInitScript('globalThis.old=callback');
      final current = js.registerFunction('callback', (_) => 2);
      expect(old.isDisposed, true);
      expect(js.eval('callback()'), 2);
      expect(js.eval('try {old();false} catch(e){true}'), true);
      expect(js.statistics.registeredCallbacks, 1);
      current.dispose();
      expect(js.statistics.registeredCallbacks, 0);
      expect(js.eval('try {callback();false} catch(e){true}'), true);
      final once = js.registerFunction('once', (_) {
        js.unregisterFunction('once');
        return 42;
      });
      expect(js.eval('once()'), 42);
      expect(once.isDisposed, true);
    } finally {
      js.dispose();
    }
  });
}
