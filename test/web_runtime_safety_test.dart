@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jsf/jsf.dart';

void main() {
  test(
      'realms isolate callbacks and global variables; disposal invalidates handles',
      () async {
    final a = JsRuntime(), b = JsRuntime();
    try {
      a.registerFunction('callback', (_) => 'A');
      b.registerFunction('callback', (_) => 'B');
      expect(a.eval('callback()'), 'A');
      expect(b.eval('callback()'), 'B');
      a.execInitScript('globalThis.privateValue=42');
      expect(b.eval('typeof privateValue'), 'undefined');
      final foreign = a.newValue(42), fn = b.evalValue('(x)=>x');
      expect(() => b.callValue(fn, [foreign]), throwsArgumentError);
      foreign.dispose();
      fn.dispose();
      final handle = a.evalValue('({value:42})');
      final pending = a.evalAsync('new Promise(()=>{})');
      final rejected = expectLater(pending, throwsStateError);
      a.dispose();
      await rejected;
      expect(() => handle.toDart(), throwsStateError);
      handle.dispose();
      expect(b.eval('callback()'), 'B');
    } finally {
      a.dispose();
      b.dispose();
    }
  });
  test('callbacks throw and promise handles expose settlement', () async {
    final js = JsRuntime();
    try {
      js.registerFunction('fail', (_) => throw StateError('failure'));
      expect(
          js.eval('try {fail();false} catch(e){e.name==="DartError"}'), true);
      js.registerHandleFunction('echo', (args) => args.first);
      expect(js.eval('echo(42)'), 42);
      final value = js.newValue(42), fn = js.evalValue('(x)=>x');
      final result = js.callValue(fn, [value]);
      expect(result.toDart(), 42);
      result.dispose();
      fn.dispose();
      value.dispose();
      final promise = js.evalValue('Promise.resolve(42)');
      expect(await js.awaitValue(promise), 42);
      expect(promise.promiseState, 1);
      final settled = promise.promiseResult();
      expect(settled.toDart(), 42);
      expect(identical(settled, promise), false);
      settled.dispose();
      promise.dispose();
      js.registerFunction('close', (_) {
        js.dispose();
        return null;
      });
      expect(
          js.eval(
              'try{close();false}catch(e){/Cannot dispose/.test(e.message)}'),
          true);
    } finally {
      js.dispose();
    }
  });
  test(
      'parsed modules preserve strings, cycles, live bindings and dynamic expressions',
      () async {
    final js = JsRuntime();
    try {
      expect(
          js.eval(r''' 'import("not-a-module")' '''), 'import("not-a-module")');
      expect(js.eval(r''' /import\("x"\)/.source '''), r'import\("x"\)');
      js.registerModules({
        'a': 'import {b} from "b"; export function a(){return b()};',
        'b': 'import {a} from "a";export function b(){return 42};',
        'state': 'export let n=1;export function inc(){n++};',
        'observer':
            'import {n,inc} from "state";export function read(){inc();return n};',
        'tla': 'export const n=await Promise.resolve(7);',
      });
      expect(await js.evalAsync('import("a").then(m=>m.a())'), 42);
      expect(await js.evalAsync('import("observer").then(m=>m.read())'), 2);
      expect(
          await js.evalAsync('const name="tla"; import(name).then(m=>m.n)'), 7);
      js.clearModules();
      js.registerModule('state', 'export const n=99;');
      expect(await js.evalAsync('import("state").then(m=>m.n)'), 2);
    } finally {
      js.dispose();
    }
  });
  test('sync TLA rejection leaves the module graph usable asynchronously',
      () async {
    final js = JsRuntime();
    try {
      js.registerModules({
        'async': 'export const value=await Promise.resolve(42);',
        'parent': 'export {value} from "async";'
      });
      expect(() => js.loadModuleValue('entry', 'import "parent";'),
          throwsA(isA<JsException>()));
      expect(await js.evalAsync('import("parent").then(m=>m.value)'), 42);
    } finally {
      js.dispose();
    }
  });
  test('browser diagnostics distinguish observed and unhandled rejections',
      () async {
    final logs = <JsConsoleEvent>[],
        rejections = <JsException>[],
        failures = <JsException>[];
    final js = JsRuntime(
        options: JsRuntimeOptions(
            onConsole: logs.add,
            onUnhandledRejection: rejections.add,
            onError: failures.add));
    try {
      js.execInitScript(
          'console.warn("hello",{value:42});Promise.reject(new TypeError("unhandled"));setTimeout(()=>{throw new Error("timer")},1)');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(logs.single.arguments, [
        'hello',
        {'value': 42}
      ]);
      expect(rejections.single.name, 'TypeError');
      expect(rejections.single.message, 'unhandled');
      expect(failures.single.message, 'timer');
      await expectLater(js.evalAsync('Promise.reject(new Error("observed"))'),
          throwsA(isA<JsException>()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(rejections.length, 1);
    } finally {
      js.dispose();
    }
  });
  test('module linking rejects missing and ambiguous exports', () async {
    final js = JsRuntime();
    try {
      js.registerModules({
        'a': 'export const value=1;',
        'b': 'export const value=2;',
        'both': 'export * from "a";export * from "b";',
        'alias': 'export {value} from "a";',
        'same': 'export * from "a";export * from "alias";',
        'missing': 'import {absent} from "a";globalThis.executed=true;',
        'ambiguous': 'import {value} from "both";export {value};'
      });
      await expectLater(
          js.evalAsync('import("missing")'), throwsA(isA<JsException>()));
      expect(js.eval('typeof executed'), 'undefined');
      await expectLater(
          js.evalAsync('import("ambiguous")'), throwsA(isA<JsException>()));
      expect(await js.evalAsync('import("both").then(m=>Object.keys(m))'), []);
      expect(await js.evalAsync('import("same").then(m=>m.value)'), 1);
    } finally {
      js.dispose();
    }
  });
}
