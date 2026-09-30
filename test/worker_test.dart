@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test('worker preserves order, modules, snapshots and host timers', () async {
    final worker = await JsWorker.start();
    try {
      await worker.setGlobal('n', 40);
      final first =
          worker.eval('new Promise(resolve=>setTimeout(()=>resolve(++n),5))');
      final second = worker.eval('++n');
      expect(await first, 41);
      expect(await second, 42);
      await worker.registerModule('module', 'export const value=42;');
      expect(await worker.eval('import("module").then(m=>m.value)'), 42);
      expect(await worker.call('(a,b)=>a+b', [20, 22]), 42);
      await expectLater(
          worker.eval('throw new TypeError("worker error")'),
          throwsA(
              isA<JsException>().having((e) => e.name, 'name', 'TypeError')));
      expect(await worker.eval('6*7'), 42);
    } finally {
      await worker.dispose();
    }
    await expectLater(worker.eval('1'), throwsStateError);
  });
  test('worker deadlines close a stalled queue and native budgets recover',
      () async {
    final worker = await JsWorker.start(
        options: const JsRuntimeOptions(timeout: Duration(milliseconds: 30)));
    await expectLater(
        worker.eval('while(true){}'), throwsA(isA<JsException>()));
    expect(await worker.eval('42'), 42);
    await expectLater(
        worker.eval('new Promise(()=>{})',
            timeout: const Duration(milliseconds: 20)),
        throwsA(
            isA<JsException>().having((e) => e.name, 'name', 'TimeoutError')));
    await worker.dispose();
  });
}
