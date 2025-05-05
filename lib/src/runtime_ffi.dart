/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'jsf_bindings.dart';
import 'runtime.dart';
import 'utils.dart';

/// The name of the native dynamic library without extension or prefix.
const String _libName = 'jsf';

/// Loads the appropriate dynamic library based on the current platform.
///
/// - On macOS/iOS: loads from `.framework` bundle.
/// - On Linux/Android: loads `.so` file.
/// - On Windows: loads `.dll` file.
///
/// Throws [UnsupportedError] if the platform is not recognized.
final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// Holds bindings to the native functions defined in the `jsf` dynamic library.
final JsfBindings _bindings = JsfBindings(_dylib);

/// A class that manages a QuickJS runtime and context for evaluating JavaScript code in Dart.
class JsRuntime implements Runtime {
  late ffi.Pointer<JSRuntime> runtime;
  late ffi.Pointer<JSContext> context;

  /// Creates a new JavaScript runtime and context.
  /// This initializes QuickJS runtime and context objects used for code evaluation.
  JsRuntime() {
    runtime = _bindings.JS_NewRuntime();
    context = _bindings.JS_NewContext(runtime);
  }

  /// Evaluates a given JavaScript [code] string within the current context.
  ///
  /// The code is evaluated using `JS_Eval` with `JS_EVAL_TYPE_GLOBAL` scope.
  ///
  /// Returns the Dart representation of the evaluated JavaScript value
  /// using [parseRawResult].
  @override
  dynamic eval(String code) {
    return using((arena) {
      final codePtr = code.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final filenamePtr =
          "<eval>".toNativeUtf8(allocator: arena).cast<ffi.Char>();

      final rawResult = _bindings.JS_Eval(
        context,
        codePtr,
        code.length,
        filenamePtr,
        JS_EVAL_TYPE_GLOBAL,
      );

      return parseRawResult(context, rawResult, _bindings);
    });
  }

  /// Executes a JavaScript initialization script without returning a result.
  ///
  /// This is useful for loading scripts that modify the runtime environment,
  /// e.g., defining functions, constants, etc.
  @override
  void execInitScript(String code) {
    eval(code);
  }

  /// Releases the QuickJS context and runtime resources.
  ///
  /// Should be called when the runtime is no longer needed to prevent memory leaks.
  @override
  void dispose() {
    _bindings.JS_FreeContext(context);
    _bindings.JS_FreeRuntime(runtime);
  }
}
