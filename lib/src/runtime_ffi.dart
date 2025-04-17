/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:ffi';
import 'dart:io';
import 'runtime.dart';
import 'package:ffi/ffi.dart' as ffi;
import '../jsf_bindings_generated.dart';

/// An implementation of [Runtime] that uses native FFI bindings to execute JavaScript code.
///
/// This runtime delegates code execution to a native dynamic library (e.g., C/C++),
/// providing more control and potentially better performance than JS interop alone.
class JsRuntime implements Runtime {
  /// Initializes the native JavaScript runtime.
  JsRuntime() {
    _bindings.qjs_init();
  }

  /// Evaluates a string of JavaScript [code] and returns the result as a Dart [String].
  ///
  /// This function:
  /// - Converts the Dart string to a native UTF-8 string.
  /// - Passes the pointer to the native `qjs_eval` function.
  /// - Converts the result back to Dart and frees the memory.
  @override
  String eval(String code) {
    final codePtr = code.toNativeUtf8().cast<Char>();
    final resultPtr = _bindings.qjs_eval(codePtr);
    ffi.malloc.free(codePtr);

    final result = resultPtr.cast<ffi.Utf8>().toDartString();
    _bindings.qjs_free_result(resultPtr);
    return result;
  }

  /// Executes a JavaScript initialization [code] snippet without returning a result.
  ///
  /// Typically used to define functions, set up the environment, or load libraries.
  @override
  void execInitScript(String code) {
    final codePtr = code.toNativeUtf8().cast<Char>();
    _bindings.qjs_exec_init_script(codePtr);
    ffi.malloc.free(codePtr);
  }

  /// Cleans up the native JavaScript runtime environment.
  ///
  /// This should be called when the runtime is no longer needed to free native resources.
  @override
  void dispose() {
    _bindings.qjs_cleanup();
  }
}

/// The name of the native dynamic library without extension or prefix.
const String _libName = 'jsf';

/// Loads the appropriate dynamic library based on the current platform.
///
/// - On macOS/iOS: loads from `.framework` bundle.
/// - On Linux/Android: loads `.so` file.
/// - On Windows: loads `.dll` file.
///
/// Throws [UnsupportedError] if the platform is not recognized.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// Holds bindings to the native functions defined in the `jsf` dynamic library.
final JsfBindings _bindings = JsfBindings(_dylib);
