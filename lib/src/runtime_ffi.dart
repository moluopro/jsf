/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'conversion.dart';
import 'exception.dart';
import 'native_bindings.dart';
import 'runtime.dart';
import 'runtime_options.dart';
import 'value.dart';

const String _libName = 'jsf';

final ffi.DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid ||
      Platform.isLinux ||
      Platform.operatingSystem == 'ohos') {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final NativeJsfBindings _bindings = NativeJsfBindings(_dylib);
final Finalizer<_RuntimeFinalizerState> _runtimeFinalizer =
    Finalizer<_RuntimeFinalizerState>(_disposeRuntimeState);

final Map<int, _ValueCallbackRegistration> _dartCallbacks = {};
final Map<int, _HandleCallbackRegistration> _dartHandleCallbacks = {};
int _nextDartCallbackId = 1;

class _RuntimeFinalizerState {
  _RuntimeFinalizerState(this.bindings, this.runtime, this.callbackIds);

  final NativeJsfBindings bindings;
  final ffi.Pointer<JSFRuntime> runtime;
  final Set<int> callbackIds;
  bool disposed = false;
}

class _ValueCallbackRegistration {
  _ValueCallbackRegistration(JsRuntime runtime, this.callback)
      : _runtime = WeakReference<JsRuntime>(runtime);

  final WeakReference<JsRuntime> _runtime;
  final Object? Function(List<Object?>) callback;

  JsRuntime? get runtime => _runtime.target;
}

class _HandleCallbackRegistration {
  _HandleCallbackRegistration(JsRuntime runtime, this.callback)
      : _runtime = WeakReference<JsRuntime>(runtime);

  final WeakReference<JsRuntime> _runtime;
  final Object? Function(List<JsValue>) callback;

  JsRuntime? get runtime => _runtime.target;
}

void _disposeRuntimeState(_RuntimeFinalizerState state) {
  if (state.disposed) {
    return;
  }
  state.disposed = true;
  for (final callbackId in state.callbackIds) {
    _dartCallbacks.remove(callbackId);
    _dartHandleCallbacks.remove(callbackId);
  }
  state.callbackIds.clear();
  disposeRuntimeValues(state.runtime);
  state.bindings.JSF_RuntimeFree(state.runtime);
}

ffi.Pointer<ffi.Char> _dartFunctionTrampoline(
  ffi.Pointer<ffi.Void> opaque,
  ffi.Pointer<ffi.Char> argsJson,
) {
  final registration = _dartCallbacks[opaque.address];
  final runtime = registration?.runtime;
  if (registration == null || runtime == null) {
    _dartCallbacks.remove(opaque.address);
    return ffi.nullptr;
  }

  try {
    final args = argsJson == ffi.nullptr
        ? const <Object?>[]
        : decodeJsTransferValue(
            jsonDecode(argsJson.cast<Utf8>().toDartString())) as List<Object?>;
    final result = registration.callback(args);
    if (result is Future) {
      final futureId = runtime._registerDartFuture(result);
      return jsonEncode({
        r'$jsf.type': 'DartFuture',
        'id': futureId,
      }).toNativeUtf8(allocator: malloc).cast<ffi.Char>();
    }
    return jsonEncode(encodeJsTransferValue(result))
        .toNativeUtf8(allocator: malloc)
        .cast<ffi.Char>();
  } catch (error) {
    return jsonEncode({
      '\$jsf.type': 'DartError',
      'message': error.toString(),
    }).toNativeUtf8(allocator: malloc).cast<ffi.Char>();
  }
}

void _freeDartCallbackResult(
  ffi.Pointer<ffi.Void> opaque,
  ffi.Pointer<ffi.Char> result,
) {
  if (result != ffi.nullptr) {
    malloc.free(result);
  }
}

final ffi.Pointer<ffi.NativeFunction<DartFunctionNative>> _dartFunctionPtr =
    ffi.Pointer.fromFunction<DartFunctionNative>(_dartFunctionTrampoline);

final ffi.Pointer<ffi.NativeFunction<DartFreeNative>> _dartFreePtr =
    ffi.Pointer.fromFunction<DartFreeNative>(_freeDartCallbackResult);

ffi.Pointer<JSFValue> _dartHandleFunctionTrampoline(
  ffi.Pointer<ffi.Void> opaque,
  ffi.Pointer<ffi.Pointer<JSFValue>> argv,
  int argc,
) {
  final registration = _dartHandleCallbacks[opaque.address];
  final runtime = registration?.runtime;
  if (registration == null || runtime == null) {
    _dartHandleCallbacks.remove(opaque.address);
    return ffi.nullptr;
  }

  final args = <JsValue>[];
  try {
    for (var i = 0; i < argc; i++) {
      args.add(
        wrapBorrowedJsValue(_bindings, runtime._runtime, argv[i],
            owner: runtime),
      );
    }
    final result = registration.callback(args);
    if (result is Future) {
      final value = runtime._newDartFutureValue(result);
      return value.releaseNativePointer();
    }
    if (result is JsValue) {
      if (result.isOwned) {
        return result.releaseNativePointer();
      }
      return _bindings.JSF_ValueDup(result.nativePointer);
    }
    final value = runtime.newValue(result);
    return value.releaseNativePointer();
  } catch (error) {
    final value = runtime.newValue({
      '\$jsf.type': 'DartError',
      'message': error.toString(),
    });
    return value.releaseNativePointer();
  } finally {
    for (final arg in args) {
      arg.dispose();
    }
  }
}

final ffi.Pointer<ffi.NativeFunction<DartHandleFunctionNative>>
    _dartHandleFunctionPtr = ffi.Pointer.fromFunction<DartHandleFunctionNative>(
  _dartHandleFunctionTrampoline,
);

/// Native QuickJS runtime used on Android, iOS, macOS, Linux, Windows, and
/// OHOS.
///
/// A runtime owns one QuickJS runtime and one context. Use it from the Dart
/// isolate where it was created, and call [dispose] when finished.
class JsRuntime implements Runtime, ffi.Finalizable {
  /// Creates a native JavaScript runtime and applies [options].
  JsRuntime({JsRuntimeOptions options = const JsRuntimeOptions()}) {
    _runtime = _bindings.JSF_RuntimeNew();
    if (_runtime == ffi.nullptr) {
      throw JsException('Unable to create JavaScript runtime.');
    }
    _finalizerState = _RuntimeFinalizerState(
      _bindings,
      _runtime,
      _callbackIds,
    );
    _runtimeFinalizer.attach(this, _finalizerState, detach: this);
    _applyOptions(options);
  }

  late ffi.Pointer<JSFRuntime> _runtime;
  late final _RuntimeFinalizerState _finalizerState;
  final Set<int> _callbackIds = <int>{};
  int _nextDartFutureId = 1;
  bool _disposed = false;

  /// Evaluates JavaScript and converts the result to a Dart snapshot.
  @override
  dynamic eval(String code, {String filename = '<eval>', bool module = false}) {
    final value = evalValue(code, filename: filename, module: module);
    try {
      return value.toDart();
    } finally {
      value.dispose();
    }
  }

  /// Evaluates JavaScript and awaits the result if it is a Promise.
  Future<dynamic> evalAsync(
    String code, {
    String filename = '<eval>',
    bool module = false,
    Duration? timeout,
  }) async {
    final value = evalValue(code, filename: filename, module: module);
    try {
      return await awaitValue(value, timeout: timeout);
    } finally {
      value.dispose();
    }
  }

  /// Evaluates JavaScript and returns an owned [JsValue] handle.
  JsValue evalValue(
    String code, {
    String filename = '<eval>',
    bool module = false,
  }) {
    _ensureAlive();
    return using((arena) {
      final codePtr = code.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final filenamePtr =
          filename.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final pointer = _bindings.JSF_Eval(
        _runtime,
        codePtr,
        filenamePtr,
        module ? 1 : 0,
      );
      return _wrapOrThrow(pointer);
    });
  }

  /// Evaluates [functionRef] as a JavaScript function expression and calls it.
  @override
  dynamic call(String functionRef, [List<Object?> arguments = const []]) {
    final function = evalValue('($functionRef)');
    try {
      final result = callValue(function, arguments);
      try {
        return result.toDart();
      } finally {
        result.dispose();
      }
    } finally {
      function.dispose();
    }
  }

  /// Calls a JavaScript function handle with Dart values converted to JS.
  JsValue callValue(JsValue function, [List<Object?> arguments = const []]) {
    _ensureAlive();
    final argv = calloc<ffi.Pointer<JSFValue>>(arguments.length);
    final created = <JsValue>[];
    try {
      for (var i = 0; i < arguments.length; i++) {
        final value = newValue(arguments[i]);
        created.add(value);
        argv[i] = value.nativePointer;
      }
      final pointer = _bindings.JSF_Call(
        _runtime,
        function.nativePointer,
        ffi.nullptr,
        argv,
        arguments.length,
      );
      return _wrapOrThrow(pointer);
    } finally {
      for (final value in created) {
        value.dispose();
      }
      calloc.free(argv);
    }
  }

  /// Awaits a JavaScript Promise handle and converts its result to Dart.
  Future<dynamic> awaitValue(
    JsValue value, {
    Duration? timeout,
  }) async {
    _ensureAlive();
    final started = DateTime.now();
    while (value.type == jsfValuePromise &&
        value.promiseState == jsfPromisePending) {
      executePendingJobs();
      if (timeout != null && DateTime.now().difference(started) > timeout) {
        throw JsException('JavaScript promise timed out after $timeout.');
      }
      await Future<void>.delayed(Duration.zero);
    }

    if (value.type != jsfValuePromise) {
      return value.toDart();
    }

    final result = value.promiseResult();
    try {
      if (value.promiseState == jsfPromiseRejected) {
        throw JsException(result.toDart().toString());
      }
      return result.toDart();
    } finally {
      result.dispose();
    }
  }

  /// Assigns a Dart value to `globalThis[name]`.
  @override
  void setGlobal(String name, Object? value) {
    final jsValue = newValue(value);
    try {
      using((arena) {
        final namePtr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
        final result =
            _bindings.JSF_SetGlobal(_runtime, namePtr, jsValue.nativePointer);
        if (result < 0) {
          _throwLastError();
        }
      });
    } finally {
      jsValue.dispose();
    }
  }

  /// Reads `globalThis[name]` as a [JsValue] handle.
  JsValue getGlobalValue(String name) {
    _ensureAlive();
    return using((arena) {
      final namePtr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(_bindings.JSF_GetGlobal(_runtime, namePtr));
    });
  }

  /// Converts a Dart value into an owned JavaScript value handle.
  JsValue newValue(Object? value) {
    _ensureAlive();
    if (value is JsValue) {
      return value.duplicate();
    }
    return using((arena) {
      final json = jsonEncode(encodeJsTransferValue(value));
      final ptr = json.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(
        _bindings.JSF_ValueNewTransferJson(_runtime, ptr),
      );
    });
  }

  /// Registers a Dart callback as `globalThis[name]`.
  void registerFunction(
    String name,
    Object? Function(List<Object?> arguments) callback,
  ) {
    _ensureAlive();
    final callbackId = _nextDartCallbackId++;
    _dartCallbacks[callbackId] = _ValueCallbackRegistration(this, callback);
    _callbackIds.add(callbackId);

    final ret = using((arena) {
      final namePtr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RegisterDartFunction(
        _runtime,
        namePtr,
        _dartFunctionPtr,
        _dartFreePtr,
        ffi.Pointer<ffi.Void>.fromAddress(callbackId),
      );
    });
    if (ret < 0) {
      _dartCallbacks.remove(callbackId);
      _callbackIds.remove(callbackId);
      _throwLastError();
    }
  }

  /// Registers a Dart callback that receives borrowed [JsValue] handles.
  void registerHandleFunction(
    String name,
    Object? Function(List<JsValue> arguments) callback,
  ) {
    _ensureAlive();
    final callbackId = _nextDartCallbackId++;
    _dartHandleCallbacks[callbackId] = _HandleCallbackRegistration(
      this,
      callback,
    );
    _callbackIds.add(callbackId);

    final ret = using((arena) {
      final namePtr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RegisterDartHandleFunction(
        _runtime,
        namePtr,
        _dartHandleFunctionPtr,
        ffi.Pointer<ffi.Void>.fromAddress(callbackId),
      );
    });
    if (ret < 0) {
      _dartHandleCallbacks.remove(callbackId);
      _callbackIds.remove(callbackId);
      _throwLastError();
    }
  }

  /// Executes pending QuickJS jobs, including Promise reactions.
  int executePendingJobs() {
    _ensureAlive();
    final result = _bindings.JSF_RuntimeExecutePendingJobs(_runtime);
    if (result < 0) {
      _throwLastError();
    }
    return result;
  }

  /// Sets the native QuickJS heap limit in bytes.
  void setMemoryLimit(int bytes) {
    _ensureAlive();
    _bindings.JSF_RuntimeSetMemoryLimit(_runtime, bytes);
  }

  /// Sets the native JavaScript stack limit in bytes.
  void setMaxStackSize(int bytes) {
    _ensureAlive();
    _bindings.JSF_RuntimeSetMaxStackSize(_runtime, bytes);
  }

  /// Enables a synchronous execution timeout.
  void setTimeout(Duration timeout) {
    _ensureAlive();
    _bindings.JSF_RuntimeSetTimeout(_runtime, timeout.inMilliseconds);
  }

  /// Clears the synchronous execution timeout.
  void clearTimeout() {
    _ensureAlive();
    _bindings.JSF_RuntimeClearTimeout(_runtime);
  }

  /// Registers and evaluates a module source.
  void loadModule(String moduleName, String moduleSource) {
    final value = loadModuleValue(moduleName, moduleSource);
    value.dispose();
  }

  /// Registers and evaluates a module source, returning the module handle.
  JsValue loadModuleValue(String moduleName, String moduleSource) {
    _ensureAlive();
    return using((arena) {
      final namePtr =
          moduleName.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final sourcePtr =
          moduleSource.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(
        _bindings.JSF_LoadModule(_runtime, namePtr, sourcePtr),
      );
    });
  }

  /// Registers an in-memory ES module.
  void registerModule(String moduleName, String moduleSource) {
    _ensureAlive();
    final ret = using((arena) {
      final namePtr =
          moduleName.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final sourcePtr =
          moduleSource.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RuntimeRegisterModule(
        _runtime,
        namePtr,
        sourcePtr,
      );
    });
    if (ret < 0) {
      _throwLastError();
    }
  }

  /// Registers multiple in-memory ES modules.
  void registerModules(Map<String, String> modules) {
    for (final entry in modules.entries) {
      registerModule(entry.key, entry.value);
    }
  }

  /// Registers import aliases used by the module resolver.
  void registerImportMap(Map<String, String> imports) {
    _ensureAlive();
    for (final entry in imports.entries) {
      final ret = using((arena) {
        final namePtr =
            entry.key.toNativeUtf8(allocator: arena).cast<ffi.Char>();
        final resolvedPtr =
            entry.value.toNativeUtf8(allocator: arena).cast<ffi.Char>();
        return _bindings.JSF_RuntimeRegisterModuleAlias(
          _runtime,
          namePtr,
          resolvedPtr,
        );
      });
      if (ret < 0) {
        _throwLastError();
      }
    }
  }

  /// Loads a Flutter asset and registers it as an ES module.
  Future<void> registerModuleFromAsset(
    String moduleName,
    String assetKey, {
    AssetBundle? bundle,
  }) async {
    final source = await (bundle ?? rootBundle).loadString(assetKey);
    registerModule(moduleName, source);
  }

  /// Clears registered in-memory modules and import aliases.
  void clearModules() {
    _ensureAlive();
    _bindings.JSF_RuntimeClearModules(_runtime);
  }

  int _registerDartFuture(Future<Object?> future) {
    final futureId = _nextDartFutureId++;
    future.then(
      (value) => _resolveDartFuture(futureId, value, isError: false),
      onError: (Object error, StackTrace stackTrace) => _resolveDartFuture(
        futureId,
        JsErrorDetails(
          name: 'DartError',
          message: error.toString(),
          stack: stackTrace.toString(),
        ),
        isError: true,
      ),
    );
    return futureId;
  }

  JsValue _newDartFutureValue(Future<Object?> future) {
    return using((arena) {
      final futureId = _registerDartFuture(future);
      final json = jsonEncode({
        r'$jsf.type': 'DartFuture',
        'id': futureId,
      });
      final ptr = json.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(
        _bindings.JSF_ValueNewTransferJson(_runtime, ptr),
      );
    });
  }

  void _resolveDartFuture(
    int futureId,
    Object? value, {
    required bool isError,
  }) {
    if (_disposed || _runtime == ffi.nullptr) {
      return;
    }
    using((arena) {
      final json = jsonEncode(encodeJsTransferValue(value));
      final ptr = json.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final result = _bindings.JSF_RuntimeResolveDartFuture(
        _runtime,
        futureId,
        ptr,
        isError ? 1 : 0,
      );
      if (result < 0 && !_disposed) {
        _throwLastError();
      }
    });
  }

  /// Executes initialization code and discards the result.
  @override
  void execInitScript(String code) {
    final value = evalValue(code);
    value.dispose();
  }

  /// Releases native runtime resources, callbacks, and live owned handles.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    for (final callbackId in _callbackIds) {
      _dartCallbacks.remove(callbackId);
      _dartHandleCallbacks.remove(callbackId);
    }
    _runtimeFinalizer.detach(this);
    _disposeRuntimeState(_finalizerState);
    _runtime = ffi.nullptr;
    _disposed = true;
  }

  void _applyOptions(JsRuntimeOptions options) {
    if (options.memoryLimitBytes != null) {
      setMemoryLimit(options.memoryLimitBytes!);
    }
    if (options.maxStackSizeBytes != null) {
      setMaxStackSize(options.maxStackSizeBytes!);
    }
    if (options.timeout != null) {
      setTimeout(options.timeout!);
    }
  }

  JsValue _wrapOrThrow(ffi.Pointer<JSFValue> pointer) {
    if (pointer == ffi.nullptr) {
      _throwLastError();
    }
    return wrapJsValue(_bindings, _runtime, pointer, owner: this);
  }

  Never _throwLastError() {
    final error = _bindings.JSF_RuntimeLastError(_runtime);
    if (error == ffi.nullptr) {
      throw JsException('Unknown JavaScript error.');
    }
    throw JsException(error.cast<Utf8>().toDartString());
  }

  void _ensureAlive() {
    if (_disposed || _runtime == ffi.nullptr) {
      throw StateError('JavaScript runtime has been disposed.');
    }
  }
}
