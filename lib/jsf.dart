/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;
import 'jsf_bindings_generated.dart';

class JsRuntime {
  JsRuntime() {
    _bindings.qjs_init();
  }

  String eval(String code) {
    final codePtr = code.toNativeUtf8().cast<Char>();
    final resultPtr = _bindings.qjs_eval(codePtr);
    ffi.malloc.free(codePtr);

    final result = resultPtr.cast<ffi.Utf8>().toDartString();
    _bindings.qjs_free_result(resultPtr);
    return result;
  }

  void execInitScript(String code) {
    final codePtr = code.toNativeUtf8().cast<Char>();
    _bindings.qjs_exec_init_script(codePtr);
    ffi.malloc.free(codePtr);
  }

  void dispose() {
    _bindings.qjs_cleanup();
  }
}

const String _libName = 'jsf';

/// The dynamic library in which the symbols for [JsfBindings] can be found.
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

/// The bindings to the native functions in [_dylib].
final JsfBindings _bindings = JsfBindings(_dylib);
