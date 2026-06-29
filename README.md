# JSF

[English](https://github.com/moluopro/jsf/blob/main/README.md) | [中文文档](https://github.com/moluopro/jsf/blob/main/README-ZH.md)

A high-performance JavaScript engine available out of the box in Flutter.

## Features

1. Up-to-date `QuickJS` support.
2. High-performance build strategy enabled by default.
3. `big number` and related features enabled by default.
4. Automatic type conversion with Dart and JavaScript interop.
5. Full platform support, including `Web` and `OHOS`.

![pic.png](pic.png)

## Basic Usage

```dart
import 'package:jsf/jsf.dart';

final js = JsRuntime();
print(js.eval('40 + 2')); // 42
```

## Runtime Options

```dart
final js = JsRuntime(
  options: const JsRuntimeOptions(
    memoryLimitBytes: 64 * 1024 * 1024,
    maxStackSizeBytes: 1024 * 1024,
    timeout: Duration(seconds: 2),
  ),
);
```

`timeout` is enforced by QuickJS' interrupt handler. Clear or replace it with:

```dart
js.clearTimeout();
js.setTimeout(const Duration(milliseconds: 500));
```

## Values And Handles

Use `eval()` when you want a Dart value. `eval()` executes JavaScript, converts the result to Dart, and releases the temporary JavaScript handle:

```dart
final data = js.eval('({id: 1n, tags: ["a", "b"]})');
// {'id': BigInt.one, 'tags': ['a', 'b']}
```

Automatic conversion rules:

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
| `NaN` / `Infinity` / `-Infinity` | Dart special `double` values |

Objects and arrays are converted recursively, so `id: 1n` becomes Dart `BigInt.one`, and `tags` becomes a Dart list. Sparse array holes become `jsArrayHole`. Passing Dart values into JS supports `null`, `jsUndefined`, `bool`, `int`, `double`, `String`, `BigInt`, `DateTime`, `Uint8List`, `JsRegExp`, `JsErrorDetails`, `JsTypedArray`, `Set`, `List`, and `Map<String, Object?>`.

`eval()` is for one-shot results and does not preserve JavaScript object identity. Use `evalValue()` when you need a `JsValue` handle:

- Calling JavaScript functions or object methods.
- Reading or writing object properties or array indexes.
- Awaiting an existing Promise.
- Handling circular references, class instances, DOM/host objects, TypedArray/ArrayBuffer, or values that cannot reliably become plain Dart maps/lists.
- Keeping the same JavaScript object identity across multiple calls.

Use `evalValue()` when you need to keep a JavaScript object/function handle:

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

`JsValue.toDart()` uses the same conversion rules as `eval()`. Circular objects cannot be converted automatically:

```dart
final circular = js.evalValue('const v = {}; v.self = v; v');
try {
  circular.toDart(); // throws JsException
} finally {
  circular.dispose();
}
```

Owned `JsValue` handles must be disposed. Handles received inside `registerHandleFunction` are borrowed and only valid for the callback duration. Call `duplicate()` if you need to keep one.

## Calling JavaScript

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

For simple calls:

```dart
js.execInitScript('function join(prefix, values) { return prefix + values.join(","); }');
print(js.call('join', ['v:', [1, 2, 3]])); // v:1,2,3
```

## Calling Dart From JavaScript

Use `registerFunction()` to expose a Dart function on the JavaScript global
object. JavaScript calls it like a normal function. Arguments are converted to
Dart values, and the return value is converted back to JavaScript:

```dart
js.registerFunction('dartSum', (args) {
  return args.cast<num>().reduce((a, b) => a + b);
});

print(js.eval('dartSum(4, 5, 6)')); // 15
```

Callbacks can receive multiple arguments and return convertible values such as
`Map`, `List`, `BigInt`, and `DateTime`:

```dart
js.registerFunction('receiveMessage', (args) {
  final name = args[0] as String;
  final payload = args[1] as Map;
  return {
    'ok': true,
    'message': '$name:${payload['count']}',
  };
});

print(js.eval('receiveMessage("counter", {count: 3}).message')); // counter:3
```

Callbacks may return `Future`; JavaScript receives a Promise, so JS can use
`await` or `.then()` directly:

```dart
js.registerFunction('loadUser', (args) async {
  return {'id': 1, 'name': 'Ada'};
});

final user = await js.evalAsync('loadUser().then((user) => user.name)');
```

With JavaScript `async/await`:

```dart
final name = await js.evalAsync('''
  (async () => {
    const user = await loadUser();
    return user.name;
  })()
''');
print(name); // Ada
```

`registerFunction()` converts JavaScript objects into Dart snapshots. Use
`registerHandleFunction()` when you need to preserve JavaScript object identity
or work with functions, class instances, circular objects, or host objects. It
passes arguments to Dart as `JsValue` handles:

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

Arguments received by `registerHandleFunction()` are borrowed handles and are
only valid for the callback duration. Call `duplicate()` if you need to keep one
outside the callback, and dispose the owned handle when finished.

## Promises

When JavaScript returns a Promise, `evalAsync()` gives you the resolved Dart
value:

```dart
final value = await js.evalAsync('Promise.resolve({ok: true})');
print(value); // {'ok': true}
```

`evalAsync()` is also the normal way to call `async function`:

```dart
final result = await js.evalAsync('''
  async function compute() {
    const value = await Promise.resolve(21);
    return value * 2;
  }
  compute()
''');
print(result); // 42
```

You can also await an existing `JsValue`:

```dart
final promise = js.evalValue('Promise.resolve(42)');
try {
  print(await js.awaitValue(promise));
} finally {
  promise.dispose();
}
```

Dart `Future` values returned to JavaScript become Promises. This works for
both `registerFunction()` and `registerHandleFunction()`:

```dart
js.registerFunction('readConfig', (args) async {
  return {'theme': 'dark'};
});

final theme = await js.evalAsync('''
  readConfig().then((config) => config.theme)
''');
print(theme); // dark
```

## ES Modules

Register modules in memory:

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

Register a Flutter asset as a module:

```dart
await js.registerModuleFromAsset('app/config', 'assets/config.js');
```

Native platforms use the QuickJS module loader. Web includes JSF's registry
loader behind the same Dart API and supports in-memory modules, import maps,
relative resolution, module caching, static `import`, named/default/namespace
exports, re-exports, and literal dynamic `import("module")`.
`evalAsync(..., module: true)` and dynamic `import()` on Web use the browser's
native ES Module/Blob loader, so browser-supported ESM syntax works, including
`export * from`, `export { x } from`, `export * as ns from`, and top-level
await. The in-memory module loader is intended for application scripts and
Flutter asset modules; it does not fetch network module URLs.

## Errors

JavaScript exceptions are thrown as `JsException`:

```dart
try {
  js.eval('throw new Error("boom")');
} on JsException catch (error) {
  print(error.message);
}
```

## Threading And Lifecycle

- A `JsRuntime` owns one QuickJS runtime and one context.
- Use a runtime from the same Dart isolate that created it.
- Dispose every runtime with `dispose()`.
- Dispose owned `JsValue` handles when you are done.
- Do not use handles after their runtime is disposed.
- Disposing a runtime also releases owned `JsValue` handles still registered under that runtime, but explicit `dispose()` remains recommended to control memory peaks.

## Platform Notes

- Native platforms use QuickJS through FFI.
- Web uses the browser JavaScript runtime and supports `eval`, `evalValue`, `call`, `setGlobal`, `execInitScript`, Promises, value callbacks, handle-style access, and JSF registry ES Modules. Memory limits, stack limits, and synchronous eval timeouts are browser platform limits; web prints debug warnings and keeps business code running where possible.
- iOS/macOS use CocoaPods source forwarding.
- Windows ships a prebuilt `windows/jsf.dll`; ordinary users do not need a C/C++ toolchain.

## Testing

Integration tests live in `example/integration_test`:

```bash
cd example
flutter drive --driver=integration_test/driver.dart --target=integration_test/js_runtime_test.dart -d macos
```

The test suite covers primitive conversion, BigInt, object/array conversion, handle calls, Dart callbacks, promise waiting, module loading, exceptions, timeouts, Unicode, typed arrays, circular objects, and multiple runtimes.
