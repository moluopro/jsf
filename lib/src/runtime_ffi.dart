/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'conversion.dart';
import 'exception.dart';
import 'fetch.dart';
import 'fetch_io.dart';
import 'fetch_js.dart';
import 'host_js.dart';
import 'host_platform_js.dart';
import 'diagnostics.dart';
import 'native_bindings.dart';
import 'runtime.dart';
import 'runtime_options.dart';
import 'value.dart';

const String _libName = 'jsf';

final ffi.DynamicLibrary _dylib = () {
  final override = Platform.environment['JSF_LIBRARY_PATH'];
  if (override != null && override.isNotEmpty) {
    return ffi.DynamicLibrary.open(override);
  }
  if (Platform.isMacOS || Platform.isIOS) {
    final process = ffi.DynamicLibrary.process();
    if (process.providesSymbol('JSF_RuntimeNew')) return process;
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

final Map<int, WeakReference<_ValueCallbackRegistration>> _dartCallbacks = {};
final Map<int, WeakReference<_HandleCallbackRegistration>>
    _dartHandleCallbacks = {};
int _nextDartCallbackId = 1;

class _RuntimeFinalizerState {
  _RuntimeFinalizerState(this.bindings, this.runtime, this.callbackIds);

  final NativeJsfBindings bindings;
  final ffi.Pointer<JSFRuntime> runtime;
  final Set<int> callbackIds;
  bool disposed = false;
  final Map<int, Timer> timers = {};
  NativeFetch? fetch;
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
  for (final timer in state.timers.values) {
    timer.cancel();
  }
  state.timers.clear();
  state.fetch?.dispose();
  state.fetch = null;
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
  final registration = _dartCallbacks[opaque.address]?.target;
  final runtime = registration?.runtime;
  if (registration == null || runtime == null) {
    _dartCallbacks.remove(opaque.address);
    return ffi.nullptr;
  }

  runtime._callbackDepth++;
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
  } catch (error, stack) {
    return jsonEncode({
      '\$jsf.type': 'DartError',
      'message': error.toString(),
      'stack': stack.toString(),
    }).toNativeUtf8(allocator: malloc).cast<ffi.Char>();
  } finally {
    runtime._callbackDepth--;
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
  final registration = _dartHandleCallbacks[opaque.address]?.target;
  final runtime = registration?.runtime;
  if (registration == null || runtime == null) {
    _dartHandleCallbacks.remove(opaque.address);
    return ffi.nullptr;
  }

  final args = <JsValue>[];
  runtime._callbackDepth++;
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
      runtime._checkOwner(result);
      if (result.isOwned) {
        return result.releaseNativePointer();
      }
      return _bindings.JSF_ValueDup(result.nativePointer);
    }
    final value = runtime.newValue(result);
    return value.releaseNativePointer();
  } catch (error, stack) {
    return using((arena) {
      final json = jsonEncode(encodeJsTransferValue(JsErrorDetails(
          name: 'DartError',
          message: error.toString(),
          stack: stack.toString())));
      return _bindings.JSF_ValueNewExceptionJson(runtime._runtime,
          json.toNativeUtf8(allocator: arena).cast<ffi.Char>());
    });
  } finally {
    for (final arg in args) {
      arg.dispose();
    }
    runtime._callbackDepth--;
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
class JsRuntime
    implements JsRuntimeApi<JsValue>, ffi.Finalizable, NativeRuntimeOwner {
  /// Creates a native JavaScript runtime and applies [options].
  JsRuntime({JsRuntimeOptions options = const JsRuntimeOptions()})
      : _options = options {
    options.validate();
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
    try {
      if (options.memoryLimitBytes != null) {
        setMemoryLimit(options.memoryLimitBytes!);
      }
      if (options.maxStackSizeBytes != null) {
        setMaxStackSize(options.maxStackSizeBytes!);
      }
      _installHost();
      if (options.fetch != null) _installFetch(options.fetch!);
      _internalCallbackCount = _callbackIds.length;
      _namedCallbacks.clear();
      _bootstrapping = false;
      _bindings.JSF_RuntimeSetRejectionTracking(
          _runtime, options.onUnhandledRejection == null ? 0 : 1);
      _applyOptions(options);
    } catch (_) {
      dispose();
      rethrow;
    }
  }

  final JsRuntimeOptions _options;
  bool _bootstrapping = true;
  int _internalCallbackCount = 0;
  final Map<String, JsCallbackRegistration> _namedCallbacks = {};
  final Map<String, int> _moduleBytes = {};
  final Set<int> _pendingFutures = {};
  final Map<int, List<JsValue>> _timerValues = {};
  int _nextTimerId = 1;
  late ffi.Pointer<JSFRuntime> _runtime;
  late final _RuntimeFinalizerState _finalizerState;
  final Set<int> _callbackIds = <int>{};
  int _nextDartFutureId = 1;
  bool _disposed = false;
  int _callbackDepth = 0;
  final Map<int, Object> _registrations = {};
  Timer? _jobTimer;
  Completer<void> _jobWakeup = Completer<void>();
  Object? _pendingJobError;

  @override
  void schedulePendingJobs() {
    _scheduleJobs();
    _notifyJobs();
  }

  void _notifyJobs() {
    final wakeup = _jobWakeup;
    _jobWakeup = Completer<void>();
    if (!wakeup.isCompleted) wakeup.complete();
  }

  void _scheduleJobs() {
    if (_disposed || _jobTimer != null) return;
    _jobTimer = Timer(Duration.zero, () {
      _jobTimer = null;
      if (_disposed) return;
      final count = _bindings.JSF_RuntimeExecutePendingJobsMax(
          _runtime, _options.jobBatchSize);
      if (count < 0) {
        try {
          _throwLastError();
        } catch (error) {
          _pendingJobError = error;
          _reportError(error);
        }
      }
      _notifyJobs();
      if (count == _options.jobBatchSize) {
        _scheduleJobs();
      } else {
        _deliverRejections();
      }
    });
  }

  void _installHost() {
    registerHandleFunction('__jsfTimerStart', (args) {
      if (_timerValues.length >= _options.maxTimers) {
        throw StateError('Timer limit exceeded.');
      }
      final function = args[0].duplicate();
      final delay = (args[1].toDart() as num).toInt();
      final repeat = args[2].toDart() as bool;
      final values = <JsValue>[function];
      try {
        for (var i = 0; i < args[3].length; i++) {
          values.add(args[3].getIndexValue(i));
        }
      } catch (_) {
        for (final value in values) {
          value.dispose();
        }
        rethrow;
      }
      final id = _nextTimerId++;
      _timerValues[id] = values;
      void fire() {
        if (_disposed || !_timerValues.containsKey(id)) return;
        try {
          function.callWithValues(values.sublist(1)).dispose();
        } catch (error) {
          _reportError(error);
        } finally {
          if (!repeat) _cancelTimer(id);
          schedulePendingJobs();
        }
      }

      final interval = Duration(milliseconds: repeat && delay < 1 ? 1 : delay);
      _finalizerState.timers[id] = repeat
          ? Timer.periodic(interval, (_) => fire())
          : Timer(interval, fire);
      return id;
    });
    registerFunction('__jsfTimerCancel', (args) {
      if (args.first is num) _cancelTimer((args.first as num).toInt());
      return null;
    });
    registerFunction('__jsfHostError', (args) {
      final error = args.first;
      _reportError(error is JsErrorDetails
          ? JsException(error.message, name: error.name, stack: error.stack)
          : JsException(error.toString()));
      return null;
    });
    if (_options.onConsole != null) {
      registerFunction('__jsfHostConsole', (args) {
        final event = JsConsoleEvent(
            args[0] as String, (args[1] as List).cast<Object?>());
        scheduleMicrotask(() => _options.onConsole?.call(event));
        return null;
      });
    }
    registerFunction('__jsfLoadPlatform', (_) {
      execInitScript(nativeHostPlatform);
      return null;
    });
    execInitScript(r'''(function(install){
      const names=['URL','URLSearchParams','TextEncoder','TextDecoder'];
      function lazy(){
        for(const name of names)Object.defineProperty(globalThis,name,{value:undefined,writable:true,configurable:true});
        try{install();}catch(error){prepare();throw error;}
      }
      function prepare(){for(const name of names)Object.defineProperty(globalThis,name,{configurable:true,get(){lazy();return globalThis[name];},set(value){Object.defineProperty(globalThis,name,{value,writable:true,configurable:true});}});}
      prepare();
    })(__jsfLoadPlatform);delete globalThis.__jsfLoadPlatform;''');
    execInitScript(
        '$nativeHostBootstrap(__jsfTimerStart,__jsfTimerCancel,__jsfHostError,${_options.onConsole == null ? 'null' : '__jsfHostConsole'});'
        'delete globalThis.__jsfTimerStart;delete globalThis.__jsfTimerCancel;delete globalThis.__jsfHostError;delete globalThis.__jsfHostConsole;');
  }

  void _cancelTimer(int id) {
    _finalizerState.timers.remove(id)?.cancel();
    final values = _timerValues.remove(id);
    if (values != null) {
      for (final value in values) {
        value.dispose();
      }
    }
  }

  void _reportError(Object error) {
    final handler = _options.onError;
    if (handler == null) return;
    final exception =
        error is JsException ? error : JsException(error.toString());
    scheduleMicrotask(() => handler(exception));
  }

  void _deliverRejections() {
    final handler = _options.onUnhandledRejection;
    if (handler == null || _disposed) return;
    while (true) {
      final pointer = _bindings.JSF_RuntimeTakeRejection(_runtime);
      if (pointer == ffi.nullptr) break;
      final value = wrapJsValue(_bindings, _runtime, pointer, owner: this);
      JsException exception;
      try {
        final details = value.toDart();
        exception = details is JsErrorDetails
            ? JsException(details.message,
                name: details.name, stack: details.stack)
            : JsException(details.toString());
      } catch (error) {
        exception = JsException(error.toString());
      } finally {
        value.dispose();
      }
      scheduleMicrotask(() => handler(exception));
    }
  }

  @override
  JsRuntimeCapabilities get capabilities => JsRuntimeCapabilities(
      engine: 'QuickJS',
      engineVersion: _bindings.JSF_EngineVersion().cast<Utf8>().toDartString(),
      abiVersion: 2,
      memoryLimits: true,
      executionTimeout: true,
      backgroundExecution: true,
      fetch: _options.fetch != null);

  @override
  JsRuntimeStatistics get statistics {
    _ensureAlive();
    final pointer = _bindings.JSF_RuntimeStatistics(_runtime);
    if (pointer == ffi.nullptr) _throwLastError();
    try {
      final data = jsonDecode(pointer.cast<Utf8>().toDartString()) as Map;
      return JsRuntimeStatistics(
          memoryUsedBytes: data['memoryUsedBytes'] as int,
          allocatedBytes: data['allocatedBytes'] as int,
          liveHandles: data['liveHandles'] as int,
          registeredCallbacks: _callbackIds.length - _internalCallbackCount,
          registeredModuleBytes: _moduleBytes.values.fold(0, (a, b) => a + b),
          pendingFutures: _pendingFutures.length,
          pendingTimers: _timerValues.length,
          activeRequests: _finalizerState.fetch?.activeRequests ?? 0);
    } finally {
      _bindings.JSF_FreeCString(pointer);
    }
  }

  void _installFetch(JsFetchOptions options) {
    options.validate();
    final fetch = NativeFetch(options);
    _finalizerState.fetch = fetch;
    registerHandleFunction('__jsfFetchSend', (args) {
      final id = args[0].toDart() as int;
      final request = args[1].toDart() as Map;
      if (args[2].type == jsfValueNull) return fetch.send(id, request, null);
      final read = args[2].duplicate(), cancel = args[3].duplicate();
      final replay = args[4].type == jsfValueNull ? null : args[4].duplicate();
      final upload = NativeFetchUpload(
        read: () async {
          final result = callValue(read);
          try {
            return await awaitValue(result) as Uint8List?;
          } finally {
            result.dispose();
          }
        },
        cancel: (reason) {
          if (_disposed || cancel.isDisposed) return;
          try {
            callValue(cancel, [
              JsErrorDetails(
                  name: reason is JsFetchException ? reason.name : 'AbortError',
                  message: reason.toString())
            ]).dispose();
          } catch (_) {/* Runtime cleanup may already be underway. */}
        },
        replay: replay == null
            ? null
            : () {
                callValue(replay).dispose();
              },
        release: () {
          read.dispose();
          cancel.dispose();
          replay?.dispose();
        },
      );
      return fetch
          .send(id, request, null, upload: upload)
          .whenComplete(upload.release);
    });
    registerFunction('__jsfFetchRead', (args) => fetch.read(args.first as int));
    registerFunction(
        '__jsfFetchWatch', (args) => fetch.watch(args.first as int));
    final random = math.Random.secure();
    registerFunction(
        '__jsfFetchBoundary',
        (_) =>
            '----jsf-${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}');
    registerFunction(
        '__jsfFetchCancel', (args) => fetch.cancel(args.first as int));
    registerFunction('__jsfFetchUrl', (args) {
      try {
        var url = Uri.parse(args.first as String);
        if (!url.hasScheme && options.baseUrl != null) {
          url = options.baseUrl!.resolveUri(url);
        }
        if (!const ['http', 'https'].contains(url.scheme) ||
            !url.hasAuthority ||
            url.host.isEmpty ||
            url.userInfo.isNotEmpty) {
          return {
            'error': 'Expected an absolute HTTP(S) URL without credentials.'
          };
        }
        return url.toString();
      } catch (_) {
        return {'error': 'Invalid URL'};
      }
    });
    final config = jsonEncode({
      'maxRequestBytes': options.maxRequestBytes,
      'maxBufferedBodyBytes': options.maxBufferedBodyBytes,
      'maxCloneBufferBytes': options.maxCloneBufferBytes,
      'maxFormDataParts': options.maxFormDataParts,
      'maxMultipartHeaderBytes': options.maxMultipartHeaderBytes,
      'maxMultipartPartBytes': options.maxMultipartPartBytes,
      'windows': Platform.isWindows,
    });
    execInitScript('(function(){ $nativeFetchPlatform;'
        '$nativeFetchBootstrap(__jsfFetchSend, __jsfFetchRead, __jsfFetchWatch, __jsfFetchCancel, __jsfFetchUrl, __jsfFetchBoundary, $config, __jsfFetchPlatform); })();'
        'delete globalThis.__jsfFetchSend; delete globalThis.__jsfFetchRead; delete globalThis.__jsfFetchWatch;'
        'delete globalThis.__jsfFetchCancel; delete globalThis.__jsfFetchUrl; delete globalThis.__jsfFetchBoundary; delete globalThis.__jsfFetchPlatform;');
  }

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
  @override
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
  @override
  JsValue evalValue(
    String code, {
    String filename = '<eval>',
    bool module = false,
  }) {
    _ensureAlive();
    _validateSource(code, 'code', allowNul: true);
    _validateSource(filename, 'filename');
    return using((arena) {
      final codePtr = code.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final filenamePtr =
          filename.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final pointer = _bindings.JSF_EvalLen(
        _runtime,
        codePtr,
        utf8.encode(code).length,
        filenamePtr,
        module ? 1 : 0,
      );
      final value = _wrapOrThrow(pointer);
      _scheduleJobs();
      _notifyJobs();
      return value;
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
  @override
  JsValue callValue(JsValue function, [List<Object?> arguments = const []]) {
    _ensureAlive();
    _checkOwner(function);
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
      final value = _wrapOrThrow(pointer);
      schedulePendingJobs();
      return value;
    } finally {
      for (final value in created) {
        value.dispose();
      }
      calloc.free(argv);
    }
  }

  /// Awaits a JavaScript Promise handle and converts its result to Dart.
  @override
  Future<dynamic> awaitValue(
    JsValue value, {
    Duration? timeout,
  }) async {
    _ensureAlive();
    _checkOwner(value);
    if (timeout != null && timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout');
    }
    if (value.type == jsfValuePromise &&
        _options.onUnhandledRejection != null) {
      if (_bindings.JSF_ValueObservePromise(value.nativePointer) < 0) {
        _throwLastError();
      }
    }
    final watch = Stopwatch()..start();
    while (value.type == jsfValuePromise &&
        value.promiseState == jsfPromisePending) {
      if (_pendingJobError != null) {
        final error = _pendingJobError!;
        _pendingJobError = null;
        throw error;
      }
      final wakeup = _jobWakeup.future;
      final count = _bindings.JSF_RuntimeExecutePendingJobsMax(
          _runtime, _options.jobBatchSize);
      if (count < 0) _throwLastError();
      if (value.promiseState != jsfPromisePending) break;
      if (count == _options.jobBatchSize) _scheduleJobs();
      if (timeout == null) {
        await wakeup;
      } else {
        final remaining = timeout - watch.elapsed;
        if (remaining <= Duration.zero) {
          throw JsException('JavaScript promise timed out after $timeout.');
        }
        try {
          await wakeup.timeout(remaining);
        } on TimeoutException {
          throw JsException('JavaScript promise timed out after $timeout.');
        }
      }
      _ensureAlive();
    }

    if (value.type != jsfValuePromise) {
      return value.toDart();
    }

    final result = value.promiseResult();
    try {
      if (value.promiseState == jsfPromiseRejected) {
        final details = result.toDart();
        if (details is JsErrorDetails) {
          throw JsException(details.message,
              name: details.name, stack: details.stack);
        }
        throw JsException(details.toString());
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
        final namePtr =
            jsonEncode(name).toNativeUtf8(allocator: arena).cast<ffi.Char>();
        final result = _bindings.JSF_SetGlobalJson(
            _runtime, namePtr, jsValue.nativePointer);
        if (result < 0) {
          _throwLastError();
        }
      });
    } finally {
      jsValue.dispose();
      schedulePendingJobs();
    }
  }

  /// Reads `globalThis[name]` as a [JsValue] handle.
  @override
  JsValue getGlobalValue(String name) {
    _ensureAlive();
    return using((arena) {
      final namePtr =
          jsonEncode(name).toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(_bindings.JSF_GetGlobalJson(_runtime, namePtr));
    });
  }

  /// Converts a Dart value into an owned JavaScript value handle.
  @override
  JsValue newValue(Object? value) {
    _ensureAlive();
    if (value is JsValue) {
      _checkOwner(value);
      return value.duplicate();
    }
    if (value == null) {
      return _wrapOrThrow(_bindings.JSF_ValueNewNull(_runtime));
    }
    if (value is JsUndefined) {
      return _wrapOrThrow(_bindings.JSF_ValueNewUndefined(_runtime));
    }
    if (value is bool) {
      return _wrapOrThrow(_bindings.JSF_ValueNewBool(_runtime, value ? 1 : 0));
    }
    if (value is int &&
        value >= -9007199254740991 &&
        value <= 9007199254740991) {
      return _wrapOrThrow(_bindings.JSF_ValueNewInt64(_runtime, value));
    }
    if (value is double) {
      return _wrapOrThrow(_bindings.JSF_ValueNewFloat64(_runtime, value));
    }
    if (value is Uint8List) {
      final allocate = _bindings.JSF_ValueAllocArrayBuffer;
      if (allocate != null) {
        return using((arena) {
          final data = arena<ffi.Pointer<ffi.Uint8>>();
          final result = _wrapOrThrow(allocate(_runtime, value.length, data));
          try {
            // The handle keeps the buffer alive. Do not execute JS between
            // allocation and this synchronous copy, or retain the native view.
            data.value.asTypedList(value.length).setAll(0, value);
            return result;
          } catch (_) {
            result.dispose();
            rethrow;
          }
        });
      }
      return using((arena) {
        final bytes = arena<ffi.Uint8>(value.isEmpty ? 1 : value.length);
        bytes.asTypedList(value.length).setAll(0, value);
        return _wrapOrThrow(
            _bindings.JSF_ValueNewArrayBuffer(_runtime, bytes, value.length));
      });
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
  @override
  JsCallbackRegistration registerFunction(
    String name,
    Object? Function(List<Object?> arguments) callback,
  ) {
    _ensureAlive();
    if (!_bootstrapping &&
        _callbackIds.length - _internalCallbackCount >= _options.maxCallbacks &&
        !_namedCallbacks.containsKey(name)) {
      throw StateError('Callback limit exceeded.');
    }
    final callbackId = _nextDartCallbackId++;
    final registration = _ValueCallbackRegistration(this, callback);
    _registrations[callbackId] = registration;
    _dartCallbacks[callbackId] = WeakReference(registration);
    _callbackIds.add(callbackId);

    final ret = using((arena) {
      final namePtr =
          jsonEncode(name).toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RegisterDartFunctionJson(
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
      _registrations.remove(callbackId);
      _throwLastError();
    }
    return _trackCallback(name, callbackId);
  }

  /// Registers a Dart callback that receives borrowed [JsValue] handles.
  @override
  JsCallbackRegistration registerHandleFunction(
    String name,
    Object? Function(List<JsValue> arguments) callback,
  ) {
    _ensureAlive();
    if (!_bootstrapping &&
        _callbackIds.length - _internalCallbackCount >= _options.maxCallbacks &&
        !_namedCallbacks.containsKey(name)) {
      throw StateError('Callback limit exceeded.');
    }
    final callbackId = _nextDartCallbackId++;
    final registration = _HandleCallbackRegistration(this, callback);
    _registrations[callbackId] = registration;
    _dartHandleCallbacks[callbackId] = WeakReference(registration);
    _callbackIds.add(callbackId);

    final ret = using((arena) {
      final namePtr =
          jsonEncode(name).toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RegisterDartHandleFunctionJson(
        _runtime,
        namePtr,
        _dartHandleFunctionPtr,
        ffi.Pointer<ffi.Void>.fromAddress(callbackId),
      );
    });
    if (ret < 0) {
      _dartHandleCallbacks.remove(callbackId);
      _callbackIds.remove(callbackId);
      _registrations.remove(callbackId);
      _throwLastError();
    }
    return _trackCallback(name, callbackId);
  }

  JsCallbackRegistration _trackCallback(String name, int id) {
    _namedCallbacks.remove(name)?.dispose();
    final weak = WeakReference(this);
    late JsCallbackRegistration registration;
    registration = JsCallbackRegistration(() {
      final runtime = weak.target;
      if (runtime == null || runtime._disposed) return;
      runtime._bindingsUnregister(id);
      if (identical(runtime._namedCallbacks[name], registration)) {
        runtime._namedCallbacks.remove(name);
      }
    });
    _namedCallbacks[name] = registration;
    return registration;
  }

  void _bindingsUnregister(int id) {
    _bindings.JSF_RuntimeUnregisterCallback(
        _runtime, ffi.Pointer<ffi.Void>.fromAddress(id));
    _registrations.remove(id);
    _callbackIds.remove(id);
    _dartCallbacks.remove(id);
    _dartHandleCallbacks.remove(id);
  }

  @override
  bool unregisterFunction(String name) {
    _ensureAlive();
    final registration = _namedCallbacks.remove(name);
    registration?.dispose();
    return registration != null;
  }

  /// Executes pending QuickJS jobs, including Promise reactions.
  @override
  int executePendingJobs() {
    _ensureAlive();
    final result = _bindings.JSF_RuntimeExecutePendingJobs(_runtime);
    if (result < 0) {
      _throwLastError();
    }
    _notifyJobs();
    return result;
  }

  /// Sets the native QuickJS heap limit in bytes.
  @override
  void setMemoryLimit(int bytes) {
    _ensureAlive();
    if (bytes <= 0) {
      throw ArgumentError.value(bytes, 'bytes', 'Must be positive.');
    }
    _bindings.JSF_RuntimeSetMemoryLimit(_runtime, bytes);
  }

  /// Sets the native JavaScript stack limit in bytes.
  @override
  void setMaxStackSize(int bytes) {
    _ensureAlive();
    if (bytes <= 0) {
      throw ArgumentError.value(bytes, 'bytes', 'Must be positive.');
    }
    _bindings.JSF_RuntimeSetMaxStackSize(_runtime, bytes);
  }

  /// Enables a synchronous execution timeout.
  @override
  void setTimeout(Duration timeout) {
    _ensureAlive();
    if (timeout.inMicroseconds <= 0 || timeout.inMicroseconds > 2147483647000) {
      throw ArgumentError.value(timeout, 'timeout',
          'Must be positive and at most 2147483647 milliseconds.');
    }
    _bindings.JSF_RuntimeSetTimeout(
        _runtime, (timeout.inMicroseconds + 999) ~/ 1000);
  }

  /// Clears the synchronous execution timeout.
  @override
  void clearTimeout() {
    _ensureAlive();
    _bindings.JSF_RuntimeClearTimeout(_runtime);
  }

  /// Registers and evaluates a module source.
  @override
  void loadModule(String moduleName, String moduleSource) {
    final value = loadModuleValue(moduleName, moduleSource);
    value.dispose();
  }

  /// Registers and evaluates a module source, returning the module handle.
  @override
  JsValue loadModuleValue(String moduleName, String moduleSource) {
    _ensureAlive();
    _validateSource(moduleName, 'moduleName');
    _validateSource(moduleSource, 'moduleSource', allowNul: true);
    final size = utf8.encode(moduleSource).length;
    if (_moduleBytes.values.fold(0, (a, b) => a + b) -
            (_moduleBytes[moduleName] ?? 0) +
            size >
        _options.maxModuleSourceBytes) {
      throw StateError('Module source limit exceeded.');
    }
    _moduleBytes[moduleName] = size;
    return using((arena) {
      final namePtr =
          moduleName.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final sourcePtr =
          moduleSource.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(
        _bindings.JSF_LoadModuleLen(
            _runtime, namePtr, sourcePtr, utf8.encode(moduleSource).length),
      );
    });
  }

  /// Registers an in-memory ES module.
  @override
  void registerModule(String moduleName, String moduleSource) {
    _ensureAlive();
    _validateSource(moduleName, 'moduleName');
    _validateSource(moduleSource, 'moduleSource', allowNul: true);
    final size = utf8.encode(moduleSource).length;
    final total = _moduleBytes.values.fold(0, (a, b) => a + b) -
        (_moduleBytes[moduleName] ?? 0) +
        size;
    if (total > _options.maxModuleSourceBytes) {
      throw StateError('Module source limit exceeded.');
    }
    final ret = using((arena) {
      final namePtr =
          moduleName.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final sourcePtr =
          moduleSource.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _bindings.JSF_RuntimeRegisterModuleLen(
        _runtime,
        namePtr,
        sourcePtr,
        utf8.encode(moduleSource).length,
      );
    });
    if (ret < 0) {
      _throwLastError();
    }
    _moduleBytes[moduleName] = size;
  }

  /// Registers multiple in-memory ES modules.
  @override
  void registerModules(Map<String, String> modules) {
    for (final entry in modules.entries) {
      registerModule(entry.key, entry.value);
    }
  }

  /// Registers import aliases used by the module resolver.
  @override
  void registerImportMap(Map<String, String> imports) {
    _ensureAlive();
    for (final entry in imports.entries) {
      _validateSource(entry.key, 'import');
      _validateSource(entry.value, 'resolved import');
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
  @override
  void clearModules() {
    _ensureAlive();
    _bindings.JSF_RuntimeClearModules(_runtime);
    _moduleBytes.clear();
  }

  int _registerDartFuture(Future<Object?> future) {
    if (_pendingFutures.length >= _options.maxPendingFutures) {
      future.ignore();
      throw StateError('Pending host Future limit exceeded.');
    }
    final futureId = _nextDartFutureId++;
    _pendingFutures.add(futureId);
    future
        .then(
      (value) => _resolveDartFuture(futureId, value, isError: false),
      onError: (Object error, StackTrace stackTrace) => _resolveDartFuture(
        futureId,
        JsErrorDetails(
          name: error is JsFetchException ? error.name : 'DartError',
          message: error is JsFetchException ? error.message : error.toString(),
          stack: stackTrace.toString(),
        ),
        isError: true,
      ),
    )
        .catchError((Object error) {
      _pendingJobError = error;
      _reportError(error);
      _notifyJobs();
    });
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
    _pendingFutures.remove(futureId);
    if (_disposed || _runtime == ffi.nullptr) {
      if (value is JsValue && value.isOwned) value.dispose();
      return;
    }
    JsValue converted;
    try {
      if (value is JsValue) _checkOwner(value);
      converted = value is JsValue ? value : newValue(value);
    } catch (error) {
      converted = newValue(
          JsErrorDetails(name: 'DartError', message: error.toString()));
      isError = true;
    }
    try {
      final result = _bindings.JSF_RuntimeResolveDartFutureValue(
          _runtime, futureId, converted.nativePointer, isError ? 1 : 0);
      if (result < 0) _throwLastError();
    } finally {
      if (converted.isOwned) converted.dispose();
      _scheduleJobs();
      _notifyJobs();
    }
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
    if (_callbackDepth != 0) {
      throw StateError(
          'Cannot dispose a runtime inside its JavaScript callback. Dispose after the outer call returns.');
    }
    for (final callbackId in _callbackIds) {
      _dartCallbacks.remove(callbackId);
      _dartHandleCallbacks.remove(callbackId);
    }
    for (final id in _timerValues.keys.toList()) {
      _cancelTimer(id);
    }
    _namedCallbacks.clear();
    _pendingFutures.clear();
    _moduleBytes.clear();
    _registrations.clear();
    _jobTimer?.cancel();
    _jobTimer = null;
    _runtimeFinalizer.detach(this);
    _disposeRuntimeState(_finalizerState);
    _runtime = ffi.nullptr;
    _disposed = true;
    _notifyJobs();
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
    schedulePendingJobs();
    return wrapJsValue(_bindings, _runtime, pointer, owner: this);
  }

  Never _throwLastError() {
    final json = _bindings.JSF_RuntimeLastErrorJson(_runtime);
    if (json != ffi.nullptr) {
      throw JsException.fromDetails(
          jsonDecode(json.cast<Utf8>().toDartString()));
    }
    final error = _bindings.JSF_RuntimeLastError(_runtime);
    if (error == ffi.nullptr) {
      throw JsException('Unknown JavaScript error.');
    }
    throw JsException(error.cast<Utf8>().toDartString());
  }

  void _checkOwner(JsValue value) {
    if (value.nativeRuntime != _runtime) {
      throw ArgumentError(
          'JavaScript value belongs to a different runtime. Copy a snapshot explicitly with toDart().');
    }
  }

  void _validateSource(String value, String name, {bool allowNul = false}) {
    if (!allowNul && value.contains('\u0000')) {
      throw ArgumentError.value(value, name,
          r'Raw NUL is not allowed; use a JavaScript \u0000 escape in string literals.');
    }
    // Encoding malformed UTF-16 as UTF-8 would silently replace code units.
    for (var i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (++i >= value.length ||
            value.codeUnitAt(i) < 0xdc00 ||
            value.codeUnitAt(i) > 0xdfff) {
          throw ArgumentError.value(value, name,
              'Unpaired surrogate in JavaScript source or metadata. Use a Unicode escape.');
        }
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        throw ArgumentError.value(value, name,
            'Unpaired surrogate in JavaScript source or metadata. Use a Unicode escape.');
      }
    }
  }

  void _ensureAlive() {
    if (_disposed || _runtime == ffi.nullptr) {
      throw StateError('JavaScript runtime has been disposed.');
    }
  }
}
