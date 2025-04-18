/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:js_interop';
import 'runtime.dart';

/// Provides a JavaScript-based implementation of the [Runtime] interface,
/// using Dart's JavaScript interop capabilities.
///
/// This runtime delegates code evaluation to the global JavaScript `eval`
/// function, allowing execution of arbitrary JavaScript code from Dart.
class JsRuntime implements Runtime {
  /// Creates a new instance of [JsRuntime].
  JsRuntime();

  /// Evaluates the given JavaScript [code] string and returns the result
  /// as a Dart [String].
  ///
  /// This uses the global JavaScript `eval` function via interop.
  /// The result is converted to a string using `toString()`.
  @override
  String eval(String code) {
    final result = jsEval(code.toJS);
    return result.toString();
  }

  /// Executes an initialization script using JavaScript [code].
  ///
  /// This is useful for setting up the environment, such as defining
  /// functions or variables before calling [eval].
  /// No result is returned.
  @override
  void execInitScript(String code) {
    jsEval(code.toJS);
  }

  /// Releases any resources used by this runtime.
  ///
  /// In this implementation, there is no resource management required,
  /// so the method is effectively a no-op.
  @override
  void dispose() {
    // Nothing to do.
  }
}

/// Links to the global JavaScript `eval` function for code execution.
///
/// This is declared as an external function using `@JS` and `JSInterop`.
@JS('eval')
external JSAny? jsEval(JSString code);
