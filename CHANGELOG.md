## 1.1.0

* Migrated iOS and macOS platforms to Swift Package Manager.
* Fixed Web module import-map resolution so relative specifiers are normalized
  against the referrer before aliases are applied, matching native behavior.
* Stopped applying aliases during Web module registration to avoid native/Web
  differences between registered names and import resolution.
* Improved the example widget test by injecting the runtime, so ordinary Flutter
  widget tests do not load the native dynamic library directly.

## 1.0.1

* Fixed Web platform compatibility detection by routing both JS interop and
  browser conditional exports to the Web runtime implementation.

## 1.0.0

* Added `OpenHarmony` platform support.
* Breaking: replaced direct QuickJS Dart bindings with a stable `JSF_*` native ABI.
* Added `JsValue` handles for object, array, function, promise, property, and index interop.
* Added Dart-to-JS and JS-to-Dart callback support, including handle callbacks.
* Added Promise bridge with `evalAsync` and `awaitValue`.
* Added Dart `Future` to JavaScript `Promise` bridging for Dart callbacks.
* Added in-memory ES module registry with static `import` and dynamic `import()`.
* Added module import maps and relative module normalization for native builds.
* Added a Web ES Module registry loader with native browser Blob module execution for async module evaluation and dynamic imports.
* Added runtime options for memory limit, max stack size, and timeout.
* Added structured transfer conversion for `undefined`, array holes, `Date`,
  `Map`, `Set`, `RegExp`, `Error`, `NaN`, infinities, `ArrayBuffer`, and
  TypedArray values.
* Added runtime-owned handle tracking so disposing a runtime releases remaining
  owned `JsValue` handles.
* Added release native optimization flags, LTO, and native CPU tuning.
* Reworked iOS/macOS CocoaPods source forwarding.
* Expanded integration tests for conversion, handles, callbacks, promises, modules, exceptions, timeouts, Unicode, typed arrays, circular objects, and multiple runtimes.

## 0.6.1

* added support for importing JS packages
* `JsRuntime` is no longer a singleton by default
* added `JS_LoadMjsModule` and `JS_InitConsole`

## 0.5.4

* update doc

## 0.5.3

* update doc

## 0.5.2

* fix "symbol not found" in windows platform

## 0.5.1

* add JSValue support
* add more qjs bindings

## 0.4.4

* update doc

## 0.4.3

* fix "TypeError: null" in web platform

## 0.4.2

* update doc
* fix bugs

## 0.4.1

* add web support

## 0.3.3

* fix bugs

## 0.3.2

* update doc
* fix bugs

## 0.3.1

* add mac/ios support
* fix bug: android-build failed

## 0.2.1

* add Windows support

## 0.1.1

* Initial release.
