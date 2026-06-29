/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

/// JSF provides a QuickJS-backed JavaScript runtime for Flutter native
/// platforms and a browser-runtime implementation for Flutter Web.
///
/// The main entry point is [JsRuntime]. Use [JsRuntime.eval] for one-shot
/// Dart values and [JsRuntime.evalValue] when JavaScript object identity or
/// handle-based interop must be preserved.
library;

export 'src/runtime_ffi.dart'
    if (dart.library.js_interop) 'src/runtime_web.dart'
    if (dart.library.html) 'src/runtime_web.dart';
export 'src/exception.dart';
export 'src/conversion.dart';
export 'src/runtime.dart';
export 'src/runtime_options.dart';
export 'src/value.dart'
    if (dart.library.js_interop) 'src/value_web.dart'
    if (dart.library.html) 'src/value_web.dart';
