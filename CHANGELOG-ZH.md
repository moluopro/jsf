## 1.0.1

* 修复 Web 平台兼容性识别：`js_interop` 和浏览器条件导出都会路由到 Web runtime 实现。

## 1.0.0

* 新增`OpenHarmony`平台的支持。
* 用稳定的 `JSF_*` 原生 ABI 替换直接 QuickJS Dart 绑定。
* 新增 `JsValue` 句柄，支持对象、数组、函数、Promise、属性和索引互操作。
* 新增 Dart 到 JS、JS 到 Dart 的回调能力，包括 handle callback。
* 新增 Promise bridge，提供 `evalAsync` 和 `awaitValue`。
* 新增 Dart callback 返回 `Future` 时自动桥接为 JavaScript `Promise`。
* 新增内存 ES Module 注册表，支持静态 `import` 和动态 `import()`。
* 新增 native 模块 import map 和相对路径模块名规范化。
* 新增 Web ES Module registry loader，异步模块求值和动态导入使用浏览器原生 Blob module 执行。
* 新增 runtime 选项：内存限制、最大栈大小和执行超时。
* 新增结构化类型转换，覆盖 `undefined`、数组空洞、`Date`、`Map`、`Set`、`RegExp`、`Error`、`NaN`、无穷大、`ArrayBuffer` 和 TypedArray。
* 新增 runtime 持有的 owned `JsValue` 跟踪，释放 runtime 时会清理仍存活的 owned handle。
* 新增 Release 原生优化参数、LTO 和 native CPU 平台策略。
* 重构 iOS/macOS 的 CocoaPods 构建方式。
* 扩展集成测试，覆盖类型转换、句柄、回调、Promise、模块、异常、超时、Unicode、TypedArray、循环对象和多 runtime。

## 0.6.1

* 新增导入 JS packages 的支持。
* `JsRuntime` 默认不再是单例。
* 新增 `JS_LoadMjsModule` 和 `JS_InitConsole`。

## 0.5.4

* 更新文档。

## 0.5.3

* 更新文档。

## 0.5.2

* 修复 Windows 平台 `symbol not found` 问题。

## 0.5.1

* 新增 JSValue 支持。
* 新增更多 qjs bindings。

## 0.4.4

* 更新文档。

## 0.4.3

* 修复 Web 平台 `TypeError: null` 问题。

## 0.4.2

* 更新文档。
* 修复若干问题。

## 0.4.1

* 新增 Web 支持。

## 0.3.3

* 修复若干问题。

## 0.3.2

* 更新文档。
* 修复若干问题。

## 0.3.1

* 新增 macOS/iOS 支持。
* 修复 Android 构建失败问题。

## 0.2.1

* 新增 Windows 支持。

## 0.1.1

* 初始版本。
