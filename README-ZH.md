# JSF

[English](https://github.com/moluopro/jsf/blob/main/README.md) | [中文文档](https://github.com/moluopro/jsf/blob/main/README-ZH.md)

一个高性能、在 Flutter 中开箱即用的 JavaScript 引擎

## 特性

1. 最新的`QuickJS`支持
2. 默认使用高性能的编译策略
3. 默认开启`big number`等特性
4. 自动处理类型转换，支持互调用
5. 全平台支持，包括`Web`和`OHOS`端

![pic.png](pic.png)

## 快速开始

```dart
import 'package:jsf/jsf.dart';

final js = JsRuntime();
print(js.eval('40 + 2')); // 42
```

## Runtime 配置

```dart
final js = JsRuntime(
  options: const JsRuntimeOptions(
    memoryLimitBytes: 64 * 1024 * 1024,
    maxStackSizeBytes: 1024 * 1024,
    timeout: Duration(seconds: 2),
  ),
);
```

`timeout` 由 QuickJS interrupt handler 执行，可以随时修改或清除：

```dart
js.clearTimeout();
js.setTimeout(const Duration(milliseconds: 500));
```

## 值和句柄

只需要 Dart 值时使用 `eval()`。`eval()` 会执行 JS，拿到结果后立即转换成 Dart 类型，并释放临时 JS handle：

```dart
final data = js.eval('({id: 1n, tags: ["a", "b"]})');
// {'id': BigInt.one, 'tags': ['a', 'b']}
```

自动转换规则：

| JavaScript | Dart |
| --- | --- |
| `undefined` | `jsUndefined` |
| `null` | `null` |
| `boolean` | `bool` |
| integer number | `int` |
| floating-point number | `double` |
| `bigint` | `BigInt` |
| `string` | `String` |
| `Array` | `List<dynamic>` |
| plain object | `Map<String, dynamic>` |
| `Date` | `DateTime` |
| `Map` / `Set` | `Map<Object?, Object?>` / `Set<Object?>` |
| `RegExp` / `Error` | `JsRegExp` / `JsErrorDetails` |
| `ArrayBuffer` / TypedArray | `Uint8List` / `JsTypedArray` |
| `NaN` / `Infinity` / `-Infinity` | Dart `double` 特殊值 |

对象和数组会递归转换，所以上面的 `id: 1n` 会变成 Dart `BigInt.one`，`tags` 会变成 `List<String>` 风格的 Dart list。稀疏数组空洞会变成 `jsArrayHole`。Dart 传入 JS 时也支持 `null`、`jsUndefined`、`bool`、`int`、`double`、`String`、`BigInt`、`DateTime`、`Uint8List`、`JsRegExp`、`JsErrorDetails`、`JsTypedArray`、`Set`、`List` 和 `Map<String, Object?>`。

`eval()` 适合一次性拿结果，不保留 JS 对象身份。下面这些情况应该使用 `evalValue()` 保留 `JsValue` handle：

- 需要调用 JS 函数或对象方法。
- 需要读写对象属性或数组下标。
- 需要等待已有 Promise。
- 需要处理循环引用、类实例、DOM/宿主对象、TypedArray/ArrayBuffer 等不能可靠转成普通 Dart Map/List 的值。
- 需要让同一个 JS 对象在多次调用之间保持 identity。

需要保留 JS 对象/函数身份时使用 `evalValue()`：

```dart
final object = js.evalValue('({count: 2, items: [3, 4]})');
try {
  final count = object.getPropertyValue('count');
  try {
    print(count.toDart()); // 2
  } finally {
    count.dispose();
  }
} finally {
  object.dispose();
}
```

`JsValue.toDart()` 和 `eval()` 使用同一套转换规则。循环对象不能自动转换：

```dart
final circular = js.evalValue('const v = {}; v.self = v; v');
try {
  circular.toDart(); // throws JsException
} finally {
  circular.dispose();
}
```

拥有所有权的 `JsValue` 必须手动 `dispose()`。`registerHandleFunction` 里收到的是 borrowed handle，只在回调期间有效；需要长期保存时调用 `duplicate()`。

## Dart 调 JS

```dart
final add = js.evalValue('(function(a, b) { return a + b; })');
try {
  final result = js.callValue(add, [20, 22]);
  try {
    print(result.toDart()); // 42
  } finally {
    result.dispose();
  }
} finally {
  add.dispose();
}
```

简单调用可以直接使用：

```dart
js.execInitScript('function join(prefix, values) { return prefix + values.join(","); }');
print(js.call('join', ['v:', [1, 2, 3]])); // v:1,2,3
```

## JS 调 Dart

普通值回调：

```dart
js.registerFunction('dartSum', (args) {
  return args.cast<num>().reduce((a, b) => a + b);
});

print(js.eval('dartSum(4, 5, 6)')); // 15
```

回调可以返回 `Future`，JS 侧会收到 Promise：

```dart
js.registerFunction('loadUser', (args) async {
  return {'id': 1, 'name': 'Ada'};
});

final user = await js.evalAsync('loadUser().then((user) => user.name)');
```

句柄回调：

```dart
js.registerHandleFunction('readModel', (args) {
  final model = args.first;
  final count = model.getPropertyValue('count');
  try {
    return count.toDart();
  } finally {
    count.dispose();
  }
});
```

## Promise

```dart
final value = await js.evalAsync('Promise.resolve({ok: true})');
print(value); // {'ok': true}
```

也可以等待已有句柄：

```dart
final promise = js.evalValue('Promise.resolve(42)');
try {
  print(await js.awaitValue(promise));
} finally {
  promise.dispose();
}
```

## ES Modules

注册内存模块：

```dart
js.registerModules({
  'math': 'export const answer = 42; export function inc(v) { return v + 1; }',
  'consumer': 'import { answer, inc } from "math"; export const result = inc(answer);',
  'pkg/relative': 'import { answer } from "../math"; export const result = answer;',
});

js.registerImportMap({'@math': 'math'});

js.eval(
  'import { result } from "consumer"; globalThis.result = result;',
  filename: 'main',
  module: true,
);

print(js.eval('result')); // 43
print(await js.evalAsync('import("@math").then((m) => m.inc(m.answer))')); // 43
```

把 Flutter asset 注册为模块：

```dart
await js.registerModuleFromAsset('app/config', 'assets/config.js');
```

Native 端由 QuickJS 模块加载器执行。Web 端内置 JSF registry loader，使用同一套 Dart API，支持内存模块、import map、相对路径解析、模块缓存、静态 `import`、命名/默认/namespace export、re-export，以及字面量形式的动态 `import("module")`。Web 的 `evalAsync(..., module: true)` 和动态 `import()` 会使用浏览器原生 ES Module/Blob loader，因此支持浏览器实现的完整 ESM 语法，包括 `export * from`、`export { x } from`、`export * as ns from` 和 top-level await。内存模块面向应用内脚本和 Flutter asset 模块，不会访问网络模块地址。

## 异常

JavaScript 异常会转换成 `JsException`：

```dart
try {
  js.eval('throw new Error("boom")');
} on JsException catch (error) {
  print(error.message);
}
```

## 线程和生命周期

- 一个 `JsRuntime` 拥有一个 QuickJS runtime 和一个 context。
- Runtime 应在创建它的 Dart isolate 中使用。
- Runtime 使用完必须 `dispose()`。
- Owned `JsValue` 使用完必须 `dispose()`。
- Runtime 释放后不能继续使用其句柄。
- Runtime 释放时会主动释放仍登记在该 runtime 下的 owned `JsValue`，但建议业务代码仍显式 `dispose()`，方便控制对象生命周期和内存峰值。

## 测试

集成测试位于 `example/integration_test`：

```bash
cd example
flutter drive --driver=integration_test/driver.dart --target=integration_test/js_runtime_test.dart -d macos
```

测试覆盖基础类型、BigInt、对象/数组、handle 调用、Dart callback、Promise、模块加载、异常、超时、Unicode、TypedArray、循环对象和多 runtime。
