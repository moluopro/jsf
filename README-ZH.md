# JSF

[English](https://github.com/moluopro/jsf/blob/main/README.md) | [中文文档](https://github.com/moluopro/jsf/blob/main/README-ZH.md)

一个高性能、在 Flutter 中开箱即用的 JavaScript 引擎

## 特性

1. 最新的`QuickJS`支持
2. 默认使用高性能的编译策略
3. 默认开启`big number`等特性
4. 自动处理类型转换，支持互调用
5. 全平台支持，包括`Web`和`OpenHarmony`端

![pic.png](pic.png)

## 快速开始

```dart
import 'package:jsf/jsf.dart';

final js = JsRuntime();
print(js.eval('40 + 2')); // 42
js.dispose();
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

`timeout` 限制一次同步 JavaScript 执行的时长，可以随时修改或清除：

```dart
js.clearTimeout();
js.setTimeout(const Duration(milliseconds: 500));
```

runtime 空闲时不消耗执行时限；`timeout` 无法中止正在执行的 Dart 回调。`evalAsync(timeout: ...)` 只限制等待结果的时间。Web 不支持同步执行时限、内存和栈大小限制，设置这些选项会抛出 `UnsupportedError`。可通过 `js.capabilities` 查询平台能力。

长时间运行或同时处理多个任务时，可调整以下限制：

| 配置 | 默认值 | 用途 |
| --- | --- | --- |
| `maxTimers` | 1024 | 原生端同时存在的定时器数量 |
| `maxCallbacks` | 4096 | 已注册的 Dart 回调数量 |
| `maxPendingFutures` | 4096 | 尚未完成的 Dart Future 数量 |
| `maxModuleSourceBytes` | 16 MiB | 已注册模块的源码总大小 |

Web 定时器由浏览器管理，其余三项限制同样适用。`memoryLimitBytes` 只限制 JavaScript 引擎的内存，应用中的 Dart 数据和网络缓冲需另行控制。

## 值和句柄

只需要结果数据时使用 `eval()`，它会将 JavaScript 结果自动转换为 Dart 值：

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
| `ArrayBuffer` / TypedArray / DataView | `Uint8List` / `JsTypedArray` / `JsDataView` |
| `NaN` / `Infinity` / `-Infinity` | Dart `double` 特殊值 |

对象和数组会递归转换；稀疏数组的空位用 `jsArrayHole` 表示。Dart 传入 JS 时支持 `null`、`jsUndefined`、`bool`、`int`、`double`、`String`、`BigInt`、`DateTime`、`Uint8List`、`JsRegExp`、`JsErrorDetails`、`JsTypedArray`、`JsDataView`、`Set`、`List` 和 `Map`。

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

自己创建的 `JsValue` 使用完后应调用 `dispose()`。`registerHandleFunction` 的参数只在回调期间有效；需要保存到回调外时，调用 `duplicate()` 并负责释放副本。

超过 JavaScript 安全整数范围的 Dart `int` 会转换为 BigInt；Web 上应直接使用 Dart `BigInt` 表达此类值。`JsTypedArray.values` 支持 BigInt 和非有限浮点数。包含非字符串键的 Dart Map 会转换为 JS Map。转换得到的二进制数据是独立副本，修改它不会影响原值。

句柄只能交给创建它的 runtime。批量使用临时句柄时可以用作用域统一释放：

```dart
final answer = withJsValues((scope) {
  final fn = scope.own(js.evalValue('(a, b) => a + b'));
  return scope.own(js.callValue(fn, [20, 22])).toDart();
});
```

异步操作使用 `withJsValuesAsync`。需要在作用域结束后继续使用某个句柄时，调用 `scope.release(value)`，并在使用完后自行 `dispose()`。

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

使用 `registerFunction()` 可以把 Dart 函数注册到 JS 全局对象。JS 侧调用方式和普通 JavaScript 函数一致，参数会自动转换成 Dart 值，返回值也会自动转换回 JS：

```dart
js.registerFunction('dartSum', (args) {
  return args.cast<num>().reduce((a, b) => a + b);
});

print(js.eval('dartSum(4, 5, 6)')); // 15
```

回调可以接收多个参数，也可以返回 `Map`、`List`、`BigInt`、`DateTime` 等可转换值：

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

Dart 回调可以返回 `Future`，JS 侧会收到 Promise，所以可以在 JS 中直接 `await` 或 `.then()`：

```dart
js.registerFunction('loadUser', (args) async {
  return {'id': 1, 'name': 'Ada'};
});

final user = await js.evalAsync('loadUser().then((user) => user.name)');
```

如果 JS 侧使用 `async/await`：

```dart
final name = await js.evalAsync('''
  (async () => {
    const user = await loadUser();
    return user.name;
  })()
''');
print(name); // Ada
```

使用 `registerFunction()` 时，JS 对象会按转换规则变成 Dart snapshot。如果需要保留 JS 对象身份、访问函数、类实例、循环对象或宿主对象，使用 `registerHandleFunction()`。它会把参数作为 `JsValue` handle 传给 Dart：

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

`registerHandleFunction()` 中收到的参数是 borrowed handle，只在回调期间有效。需要保存到回调外时，调用 `duplicate()` 获取 owned handle，并在使用完后 `dispose()`。

回调注册返回 `JsCallbackRegistration`，调用其 `dispose()` 或 `js.unregisterFunction(name)` 可注销。同名重新注册后，JS 中保存的旧函数将无法继续调用。同步 Dart 异常可在 JS 中通过 `try/catch` 捕获，Future 失败则会拒绝对应 Promise。请在当前 JS 调用结束后释放 runtime，回调内调用 `js.dispose()` 会报错。

## Promise

JS 返回 Promise 时，使用 `evalAsync()` 可以直接得到 Dart `Future` 的结果：

```dart
final value = await js.evalAsync('Promise.resolve({ok: true})');
print(value); // {'ok': true}
```

`evalAsync()` 也适合调用 `async function`：

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

也可以等待已有句柄：

```dart
final promise = js.evalValue('Promise.resolve(42)');
try {
  print(await js.awaitValue(promise));
} finally {
  promise.dispose();
}
```

Dart `Future` 返回给 JS 时会变成 Promise。这个能力适用于 `registerFunction()` 和 `registerHandleFunction()`：

```dart
js.registerFunction('readConfig', (args) async {
  return {'theme': 'dark'};
});

final theme = await js.evalAsync('''
  readConfig().then((config) => config.theme)
''');
print(theme); // dark
```

## Fetch

在 JavaScript 中使用 `fetch()` 发送 HTTP 请求，读取 JSON、文本或二进制数据。创建 runtime 时通过 `JsFetchOptions` 启用：

```dart
final js = JsRuntime(
  options: const JsRuntimeOptions(fetch: JsFetchOptions()),
);

final result = await js.evalAsync('''
  fetch('https://example.com/api').then(async response => {
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error('HTTP ' + response.status);
    }
    return response.json();
  })
''');
print(result);
```

HTTP 4xx/5xx 也会返回 Response，需要通过 `response.ok` 或 `response.status` 判断请求是否成功。根据返回内容，可以使用 `text()`、`json()`、`bytes()`、`arrayBuffer()`、`blob()` 或 `formData()` 读取正文。同一份正文只能读取一次。

**流式读取**

对于 AI 输出、SSE 等持续返回数据的接口，可以逐段读取 `response.body`。下面将收到的 UTF-8 文本传回 Dart：

```dart
js.registerFunction('onChunk', (args) {
  print(args.first);
  return null;
});

await js.evalAsync('''
  (async () => {
    const response = await fetch('https://example.com/events');
    if (!response.ok) {
      await response.body?.cancel();
      throw new Error('HTTP ' + response.status);
    }
    const stream = response.body.pipeThrough(new TextDecoderStream());
    for await (const text of stream) {
      onChunk(text);
    }
  })()
''');
```

每次收到的文本不一定是完整的 SSE 事件，需要按照接口的数据格式继续解析。如果不再需要响应内容，调用 `response.body.cancel()` 结束读取；使用 reader 时调用 `reader.cancel()`。也可以将 `AbortController.signal` 传给 fetch，再调用 `abort()` 取消整个请求。`evalAsync(timeout: ...)` 只停止 Dart 等待，不会取消网络请求。

**上传文件和表单**

在 JavaScript 中使用 `FormData` 组合文本和文件。文件内容可以来自字符串、ArrayBuffer 或 TypedArray：

```javascript
const form = new FormData();
form.append('title', '示例附件');
form.append('file', new File(
  [new Uint8Array([0, 128, 255])],
  'sample.bin',
  {type: 'application/octet-stream'},
));

fetch('https://example.com/upload', {
  method: 'POST',
  body: form,
}).then(async response => {
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error('HTTP ' + response.status);
  }
  return response.json();
});
```

使用 FormData 时无需手动设置 `Content-Type`。同名字段可以多次 `append()`；URL 编码表单可使用 `URLSearchParams`。Blob/File 的内容需自行提供，指定文件名不会读取本地文件。

原生端支持将 `ReadableStream` 作为请求正文，边生成边上传。遇到 307/308 等需要重新发送正文的重定向时，Blob/FormData 等固定内容可以重发；无法重复读取的流会报错。

如需自定义网络请求，可通过 `JsFetchOptions.transport` 传入 `JsFetchTransport` 实现；支持流式上传的实现应使用 `JsStreamingFetchTransport`。

`response.formData()` 返回完整表单，大小受 `maxBufferedBodyBytes` 限制。原生端还可使用 `response.formDataParts()` 逐项处理较大的表单，每次得到 `{name, value}`，其中 value 为字符串或 File：

```javascript
for await (const part of response.formDataParts()) {
  await processPart(part.name, part.value);
}
```

每项在读取完整后返回，大小不能超过 `maxMultipartPartBytes`；提前退出循环会取消读取。

**超时和大小限制**

通过 `JsFetchOptions` 调整常用配置：

| 配置 | 默认值 | 说明 |
| --- | --- | --- |
| `headersTimeout` | 30 秒 | 等待响应头的最长时间，包括重定向 |
| `bodyIdleTimeout` | 30 秒 | 读取正文时，等待下一段数据的最长时间 |
| `timeout` | `null` | 整个请求的时间上限，默认不限制 |
| `maxConcurrentRequests` | 16 | 同时进行的请求数量上限 |
| `uploadIdleTimeout` | 30 秒 | 等待下一段待上传数据的最长时间 |
| `maxTotalBufferedBytes` | 32 MiB | 原生请求共用的传输缓冲上限 |
| `maxMultipartPartBytes` | 8 MiB | 增量表单解析的单项缓冲上限 |
| `maxRequestBytes` | 8 MiB | 上传大小上限，包含表单编码后的内容 |
| `maxBufferedBodyBytes` | 8 MiB | 使用 text/json 等方法一次性读取正文的大小上限 |

`maxTotalBufferedBytes` 仅限制传输过程中缓存的数据；脚本中创建或保留的数据需另行控制。

长连接可保持 `timeout: null`，并根据服务端心跳间隔增大 `bodyIdleTimeout`，或设为 null。下载较大内容时，可逐段读取 `response.body`；需要一次性读取时，提高 `maxBufferedBodyBytes`。如需限制包含流式读取在内的响应总大小，设置 `maxResponseBytes`。

以上配置用于 Android、iOS、macOS、Windows、Linux 和 OHOS。原生端不自动管理 Cookie，认证信息可通过 Authorization 请求头传入。Web 直接使用浏览器 Fetch，跨域、凭据和请求限制遵循浏览器规则。

runtime 使用完成后调用 `js.dispose()`；仍在进行的请求会一并取消。

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

原生端与 Web 使用相同的模块注册 API，支持相对路径、import map、静态导入、动态 `import()`、循环依赖和 re-export。模块使用 top-level await 时，请通过 `evalAsync` 执行。模块源码需要提前注册，不会自动从网络下载。

Web 暂不支持 import attributes。存在循环依赖时，请在依赖模块初始化完成后再读取其变量或类导出，提前读取的行为可能与原生端不同。Web 页面的内容安全策略（CSP）需允许动态执行 JavaScript 和同源 iframe。

`clearModules()` 清除已注册源码与 import map，已加载模块仍会保留。需要加载修改后的代码时，请使用新的模块名或重新创建 runtime。

## 异常

JavaScript 异常会转换成 `JsException`：

```dart
try {
  js.eval('throw new Error("boom")');
} on JsException catch (error) {
  print(error.message);
}
```

`JsException` 提供 `name`、`message`、`stack` 和可选 `cause`。可根据 `name` 区分错误类型，通过 `stack` 定位调用位置；原生端的 `cause` 为文本描述。

## 常用 API 与诊断

原生端可直接使用 `setTimeout` / `setInterval`、`clearTimeout` / `clearInterval`、`queueMicrotask`、`URL` / `URLSearchParams`、UTF-8 `TextEncoder` / `TextDecoder` 和 `AbortController` / `AbortSignal.abort/any/timeout`，无需启用 Fetch。Web 使用浏览器提供的对应 API。

通过 `JsRuntimeOptions(onConsole: ..., onUnhandledRejection: ..., onError: ...)` 接收 console 输出、未处理的 Promise 错误以及定时器/异步任务错误。需要检查资源使用情况时，读取 `js.statistics`，可获取句柄、回调、待完成 Future、模块源码大小及原生内存和请求数量；当前平台无法提供的指标为 `null`。

## 后台执行

`evalAsync` 不会自动将计算移到后台。原生端运行耗时脚本时，可使用 `JsWorker` 避免阻塞当前 isolate：

```dart
final worker = await JsWorker.start();
try {
  print(await worker.eval('40 + 2', timeout: const Duration(seconds: 2)));
} finally {
  await worker.dispose();
}
```

Worker 按顺序处理请求，默认最多允许 128 个未完成请求，每次同步 JS 执行最长 5 秒。参数和结果以数据副本传递，不接受 `JsValue`、Dart 回调或自定义网络传输对象。请求超时会关闭 worker 并取消其余等待中的请求，`dispose()` 完成后才可确认资源已释放。Web 暂不支持 `JsWorker`。

## 线程和生命周期

- 不同 runtime 的全局变量相互独立，`JsValue` 只能在所属 runtime 中使用。
- Runtime 应在创建它的 Dart isolate 中使用。
- Runtime 使用完必须 `dispose()`。
- 自己创建或通过 `duplicate()` 得到的 `JsValue` 使用完必须 `dispose()`。
- Runtime 释放后不能继续使用其句柄。
- Runtime 释放时也会释放其持有的句柄；及时释放不再使用的句柄可降低内存占用。

Web 脚本仍拥有页面的同源访问权限，实例之间的全局变量隔离不能用于安全执行不可信脚本。原生端启用 Fetch 后，可通过 `allowRequest` 限制请求及重定向的目标地址。

原生端不提供自动 Cookie 管理、HTTP 缓存、CORS 模拟、WebSocket、DOM 或 Node.js 内置模块。使用第三方 JS 库前，请确认它所依赖的 API。
