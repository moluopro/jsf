/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:js_interop';
import 'runtime.dart';

/// A concrete implementation of the [Runtime] interface that evaluates JavaScript code.
///
/// This class provides a runtime environment specifically for executing JavaScript code
/// within a Dart application, typically in a Web or JS-compatible environment (e.g., Flutter Web).
/// It delegates actual code execution to a JavaScript `eval` function via Dart's JS interop.
class JsRuntime implements Runtime {
  /// Constructs a [JsRuntime] instance.
  ///
  /// This constructor doesn't perform any initialization logic,
  /// but it provides a standard way to instantiate the JavaScript runtime.
  JsRuntime();

  /// Evaluates a JavaScript expression and returns the result.
  ///
  /// The [code] parameter should be a valid JavaScript expression as a Dart [String].
  /// It will be automatically converted to a JS-compatible string before being passed
  /// to the underlying JavaScript `eval` function.
  ///
  /// Returns the result of the evaluated JavaScript expression as a dynamic value.
  @override
  dynamic eval(String code) {
    final jsResult = jsEval(code.toJS);
    if (jsResult == null) {
      return null;
    }
    return jsResult.dartify();
  }

  /// Executes a JavaScript initialization script.
  ///
  /// This is typically used to run global setup code in the JS environment, such as
  /// defining functions or variables before other evaluations.
  @override
  void execInitScript(String code) {
    jsEval(code.toJS);
  }

  /// Disposes of the runtime environment.
  ///
  /// In this implementation, there are no resources to release or cleanup logic to perform,
  /// so this method does nothing.
  @override
  void dispose() {
    // Nothing to do.
  }
}

/// Binds to the global JavaScript `eval` function using Dart JS interop.
///
/// This allows Dart code to call JavaScript's native `eval` function to
/// execute arbitrary JavaScript code at runtime.
///
/// The [code] parameter is a [JSString], which represents a JavaScript string.
/// The function returns a [JSAny?], which is the result of the evaluated expression.
@JS('eval')
external JSAny? jsEval(JSString code);
