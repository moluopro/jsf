/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';

import 'conversion.dart';
import 'diagnostics.dart';
import 'exception.dart';
import 'runtime.dart';
import 'runtime_options.dart';
import 'value_web.dart';

/// Browser JavaScript runtime used by Flutter Web.
///
/// This implementation mirrors the native API where the browser platform
/// allows it. Each runtime has its own browser realm. Native memory, stack and
/// synchronous execution limits throw [UnsupportedError].
class JsRuntime implements JsRuntimeApi<JsValue> {
  /// Creates a browser-backed JavaScript runtime.
  JsRuntime({JsRuntimeOptions options = const JsRuntimeOptions()})
      : _options = options {
    options.validate();
    if (options.fetch != null) {
      options.fetch!.validate();
      if (options.fetch!.transport != null ||
          options.fetch!.baseUrl != null ||
          options.fetch!.allowRequest != null) {
        throw UnsupportedError(
            'Native Fetch transport, baseUrl and URL policies are not applied on Web. Use browser fetch.');
      }
    }
    ensureJsWebHelpers();
    _global = _jsfCreateRealm(_moduleRuntimeId.toJS);
    _owner.realm = _global;
    if (options.memoryLimitBytes != null ||
        options.maxStackSizeBytes != null ||
        options.timeout != null) {
      _jsfModuleDispose(_moduleRuntimeId.toJS);
      throw UnsupportedError(
          'Memory, stack and synchronous execution limits cannot be enforced by the browser.');
    }
    _installDiagnostics();
  }

  final JsRuntimeOptions _options;
  final Map<String, JsCallbackRegistration> _namedCallbacks = {};
  final Map<String, int> _moduleBytes = {};
  late final JSObject _global;
  final _owner = WebValueOwner();
  final Set<Completer<dynamic>> _pendingWaits = {};
  int _pendingHostFutures = 0;
  int _callbackDepth = 0;
  final Set<String> _registeredCallbackNames = <String>{};
  final Set<Object> _registeredCallbacks = <Object>{};
  final String _moduleRuntimeId = 'jsf_web_${_nextRuntimeId++}';

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
  @override
  Future<dynamic> evalAsync(
    String code, {
    String filename = '<eval>',
    bool module = false,
    Duration? timeout,
  }) async {
    _ensureAlive();
    ensureJsWebHelpers(modules: module || code.contains('import'));
    final value = module
        ? JsValue(
            webInterop(() => _jsfModuleEvalAsync(
                  _moduleRuntimeId.toJS,
                  code.toJS,
                  filename.toJS,
                )),
            owner: _owner)
        : evalValue(code, filename: filename);
    try {
      return await awaitValue(value, timeout: timeout);
    } finally {
      value.dispose();
    }
  }

  /// Evaluates JavaScript and returns a browser-backed [JsValue].
  @override
  JsValue evalValue(
    String code, {
    String filename = '<eval>',
    bool module = false,
  }) {
    _ensureAlive();
    ensureJsWebHelpers(modules: module || code.contains('import'));
    if (module) {
      return JsValue(
          webInterop(() => _jsfModuleEval(
                _moduleRuntimeId.toJS,
                code.toJS,
                filename.toJS,
              )),
          owner: _owner);
    }
    return JsValue(
        webInterop(() => _jsfEval(
              _moduleRuntimeId.toJS,
              code.toJS,
              filename.toJS,
            )),
        owner: _owner);
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
    final values = <JsValue>[];
    try {
      for (final value in arguments) {
        values.add(newValue(value));
      }
      return function.callWithValues(values);
    } finally {
      for (final value in values) {
        value.dispose();
      }
    }
  }

  /// Assigns a Dart value to `globalThis[name]`.
  @override
  void setGlobal(String name, Object? value) {
    _ensureAlive();
    final wrapped = newValue(value);
    try {
      webInterop(() => _global[name] = wrapped.nativeValue);
    } finally {
      wrapped.dispose();
    }
  }

  /// Reads `globalThis[name]` as a [JsValue] handle.
  @override
  JsValue getGlobalValue(String name) {
    _ensureAlive();
    return JsValue(webInterop(() => _global[name]), owner: _owner);
  }

  /// Converts a Dart value into a JavaScript value handle.
  @override
  JsValue newValue(Object? value) {
    _ensureAlive();
    if (value is JsValue) {
      _checkOwner(value);
      return value.duplicate();
    }
    return JsValue(webValueFromDart(value, _global), owner: _owner);
  }

  /// Awaits a JavaScript Promise-like value and converts its result to Dart.
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
    webObservePromise(value.nativeValue);
    final waiter = Completer<dynamic>();
    _pendingWaits.add(waiter);
    jsPromiseResolve(value.nativeValue).toDart.then((resolved) {
      if (!waiter.isCompleted) {
        try {
          waiter.complete(webValueToDart(resolved));
        } catch (error, stack) {
          waiter.completeError(error, stack);
        }
      }
    }, onError: (Object error, StackTrace stack) {
      if (!waiter.isCompleted) waiter.completeError(webException(error), stack);
    });
    final result = waiter.future;
    try {
      return await (timeout == null ? result : result.timeout(timeout));
    } on TimeoutException {
      throw JsException('JavaScript promise timed out after $timeout.',
          name: 'TimeoutError');
    } catch (error) {
      if (error is StateError || error is ArgumentError) rethrow;
      throw webException(error);
    } finally {
      _pendingWaits.remove(waiter);
    }
  }

  /// Registers a Dart callback as `globalThis[name]`.
  @override
  JsCallbackRegistration registerFunction(
    String name,
    Object? Function(List<Object?> arguments) callback,
  ) {
    _ensureAlive();
    return _registerCallback(name, (args) {
      final values = webValueToDart(args);
      return callback(values is List ? values.cast<Object?>() : const []);
    });
  }

  /// Registers a callback with borrowed handles, valid only during the callback.
  @override
  JsCallbackRegistration registerHandleFunction(
      String name, Object? Function(List<JsValue>) callback) {
    _ensureAlive();
    return _registerCallback(name, (raw) {
      final list = JsValue(raw, owner: _owner, owned: false);
      final args = <JsValue>[];
      try {
        for (var i = 0; i < list.length; i++) {
          final item = list.getIndexValue(i);
          args.add(JsValue(item.nativeValue, owner: _owner, owned: false));
          item.dispose();
        }
        final result = callback(args);
        // A returned borrowed handle must remain usable until the envelope is built.
        if (result is JsValue) _checkOwner(result);
        return result is JsValue ? result.duplicate() : result;
      } finally {
        for (final value in args) {
          value.dispose();
        }
        list.dispose();
      }
    });
  }

  JsCallbackRegistration _registerCallback(
      String name, Object? Function(JSAny?) callback) {
    if (_namedCallbacks.length >= _options.maxCallbacks &&
        !_namedCallbacks.containsKey(name)) {
      throw StateError('Callback limit exceeded.');
    }
    JSAny? invoke(JSAny? args) {
      _callbackDepth++;
      try {
        _ensureAlive();
        final result = _toJsCallbackResult(callback(args));
        final envelope = JSObject();
        envelope['error'] = false.toJS;
        envelope['value'] = result;
        return envelope;
      } catch (error, stack) {
        final envelope = JSObject();
        envelope['error'] = true.toJS;
        envelope['value'] = webValueFromDart(
            JsErrorDetails(
                name: 'DartError',
                message: error.toString(),
                stack: stack.toString()),
            _global);
        return envelope;
      } finally {
        _callbackDepth--;
      }
    }

    final bridge = _jsfCallback(invoke.toJS, _global);
    _namedCallbacks.remove(name)?.dispose();
    _registeredCallbacks.add(bridge);
    _global[name] = bridge['function'];
    _registeredCallbackNames.add(name);
    late JsCallbackRegistration registration;
    registration = JsCallbackRegistration(() {
      bridge.callMethod<JSAny?>('dispose'.toJS);
      _registeredCallbacks.remove(bridge);
      if (identical(_namedCallbacks[name], registration)) {
        _namedCallbacks.remove(name);
      }
    });
    _namedCallbacks[name] = registration;
    return registration;
  }

  @override
  bool unregisterFunction(String name) {
    _ensureAlive();
    final token = _namedCallbacks.remove(name);
    token?.dispose();
    return token != null;
  }

  @override
  JsRuntimeCapabilities get capabilities => const JsRuntimeCapabilities(
      engine: 'browser',
      engineVersion: 'host',
      abiVersion: null,
      memoryLimits: false,
      executionTimeout: false,
      backgroundExecution: false,
      fetch: true);
  @override
  JsRuntimeStatistics get statistics {
    _ensureAlive();
    return JsRuntimeStatistics(
        liveHandles: _owner.liveHandles,
        registeredCallbacks: _namedCallbacks.length,
        registeredModuleBytes: _moduleBytes.values.fold(0, (a, b) => a + b),
        pendingFutures: _pendingHostFutures,
        pendingTimers: null,
        activeRequests: null);
  }

  /// Executes pending jobs.
  ///
  /// Browser Promise jobs are owned by the browser event loop, so this is a
  /// no-op on web.
  @override
  int executePendingJobs() {
    _ensureAlive();
    return 0;
  }

  /// Reports that native memory limits are not enforceable on web.
  @override
  void setMemoryLimit(int bytes) {
    _ensureAlive();
    throw UnsupportedError('Browser memory limits are not supported.');
  }

  /// Reports that native stack limits are not enforceable on web.
  @override
  void setMaxStackSize(int bytes) {
    _ensureAlive();
    throw UnsupportedError('Browser stack limits are not supported.');
  }

  /// Reports that synchronous browser eval timeouts are not enforceable.
  @override
  void setTimeout(Duration timeout) {
    _ensureAlive();
    throw UnsupportedError(
        'Synchronous browser execution timeouts are not supported.');
  }

  /// Clears timeout settings.
  @override
  void clearTimeout() {
    _ensureAlive();
  }

  /// Registers and evaluates a module source.
  @override
  void loadModule(String moduleName, String moduleSource) {
    loadModuleValue(moduleName, moduleSource).dispose();
  }

  /// Registers and evaluates a module, returning its namespace handle.
  @override
  JsValue loadModuleValue(String moduleName, String moduleSource) {
    registerModule(moduleName, moduleSource);
    ensureJsWebHelpers(modules: true);
    return JsValue(
        webInterop(
            () => _jsfModuleLoad(_moduleRuntimeId.toJS, moduleName.toJS)),
        owner: _owner);
  }

  /// Registers an in-memory module source.
  @override
  void registerModule(String moduleName, String moduleSource) {
    _ensureAlive();
    final size = utf8.encode(moduleSource).length;
    if (_moduleBytes.values.fold(0, (a, b) => a + b) -
            (_moduleBytes[moduleName] ?? 0) +
            size >
        _options.maxModuleSourceBytes) {
      throw StateError('Module source limit exceeded.');
    }
    _moduleBytes[moduleName] = size;
    _jsfModuleRegister(
      _moduleRuntimeId.toJS,
      moduleName.toJS,
      moduleSource.toJS,
    );
  }

  /// Registers multiple in-memory module sources.
  @override
  void registerModules(Map<String, String> modules) {
    modules.forEach(registerModule);
  }

  /// Registers import aliases for best-effort web module resolution.
  @override
  void registerImportMap(Map<String, String> imports) {
    _ensureAlive();
    for (final entry in imports.entries) {
      _jsfModuleAlias(
        _moduleRuntimeId.toJS,
        entry.key.toJS,
        entry.value.toJS,
      );
    }
  }

  /// Loads a Flutter asset and registers it as a module.
  Future<void> registerModuleFromAsset(
    String moduleName,
    String assetKey, {
    AssetBundle? bundle,
  }) async {
    final source = await (bundle ?? rootBundle).loadString(assetKey);
    registerModule(moduleName, source);
  }

  /// Clears registered in-memory modules.
  @override
  void clearModules() {
    _ensureAlive();
    _jsfModuleClear(_moduleRuntimeId.toJS);
    _moduleBytes.clear();
  }

  /// Executes initialization code and discards the result.
  @override
  void execInitScript(String code) {
    _ensureAlive();
    final value = evalValue(code);
    value.dispose();
  }

  /// Releases registered browser callback wrappers and module metadata.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    if (_callbackDepth != 0) {
      throw StateError(
          'Cannot dispose a runtime inside its JavaScript callback.');
    }
    for (final registration in _namedCallbacks.values.toList()) {
      registration.dispose();
    }
    _moduleBytes.clear();
    _global['__jsfDisposed'] = true.toJS;
    _owner.dispose();
    for (final pending in _pendingWaits) {
      if (!pending.isCompleted) {
        pending
            .completeError(StateError('JavaScript runtime has been disposed.'));
      }
    }
    _pendingWaits.clear();
    _registeredCallbackNames.clear();
    _registeredCallbacks.clear();
    _jsfModuleDispose(_moduleRuntimeId.toJS);
    _disposed = true;
  }

  void _checkOwner(JsValue value) {
    value.nativeValue;
    if (!identical(value.owner, _owner)) {
      throw ArgumentError('JavaScript value belongs to a different runtime.');
    }
  }

  JSAny? _toJsCallbackResult(Object? result) {
    if (result is JsValue) {
      _checkOwner(result);
      final value = result.nativeValue;
      if (result.isOwned) result.dispose();
      return value;
    }
    if (result is Future) {
      if (_pendingHostFutures >= _options.maxPendingFutures) {
        result.ignore();
        throw StateError('Pending host Future limit exceeded.');
      }
      _pendingHostFutures++;
      final completion = result.then<JSAny?>((value) {
        try {
          _ensureAlive();
          return _callbackEnvelope(value, false);
        } catch (error, stack) {
          return _callbackEnvelope(error, true, stack);
        }
      }, onError: (Object error, StackTrace stack) {
        return _callbackEnvelope(error, true, stack);
      }).whenComplete(() => _pendingHostFutures--);
      return _jsfUnwrapFuture(completion.toJS);
    }
    return webValueFromDart(result, _global);
  }

  JSObject _callbackEnvelope(Object? value, bool error, [StackTrace? stack]) {
    final envelope = JSObject();
    envelope['error'] = error.toJS;
    envelope['value'] = error
        ? webValueFromDart(
            JsErrorDetails(
                name: value is JsException ? value.name : 'DartError',
                message:
                    value is JsException ? value.message : value.toString(),
                stack: value is JsException ? value.stack : stack?.toString()),
            _global)
        : _toJsCallbackResult(value);
    return envelope;
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('JavaScript runtime has been disposed.');
    }
  }

  void _installDiagnostics() {
    JSFunction? log, rejection, failure;
    if (_options.onConsole != null) {
      void emit(JSAny? level, JSAny? values) {
        if (_disposed) return;
        final event = JsConsoleEvent(level.dartify().toString(),
            (webValueToDart(values) as List).cast<Object?>());
        scheduleMicrotask(() => _options.onConsole?.call(event));
      }

      log = emit.toJS;
    }
    if (_options.onUnhandledRejection != null) {
      void emit(JSAny? error) {
        if (!_disposed) {
          final exception = webException(error as Object);
          scheduleMicrotask(
              () => _options.onUnhandledRejection?.call(exception));
        }
      }

      rejection = emit.toJS;
    }
    if (_options.onError != null) {
      void emit(JSAny? error) {
        if (!_disposed) {
          final exception = webException(error as Object);
          scheduleMicrotask(() => _options.onError?.call(exception));
        }
      }

      failure = emit.toJS;
    }
    _jsfInstallDiagnostics(_global, log, rejection, failure);
  }
}

int _nextRuntimeId = 1;

@JS('eval')
external JSAny? jsEval(JSString code);

@JS('Promise.resolve')
external JSPromise<JSAny?> jsPromiseResolve(JSAny? value);

@JS('__jsfEval')
external JSAny? _jsfEval(JSString runtimeId, JSString code, JSString filename);

@JS('__jsfModuleEval')
external JSAny? _jsfModuleEval(
  JSString runtimeId,
  JSString code,
  JSString filename,
);

@JS('__jsfModuleEvalAsync')
external JSAny? _jsfModuleEvalAsync(
  JSString runtimeId,
  JSString code,
  JSString filename,
);

@JS('__jsfModuleLoad')
external JSAny? _jsfModuleLoad(JSString runtimeId, JSString moduleName);

@JS('__jsfModuleRegister')
external void _jsfModuleRegister(
  JSString runtimeId,
  JSString moduleName,
  JSString moduleSource,
);

@JS('__jsfModuleAlias')
external void _jsfModuleAlias(
  JSString runtimeId,
  JSString moduleName,
  JSString resolvedName,
);

@JS('__jsfModuleClear')
external void _jsfModuleClear(JSString runtimeId);

@JS('__jsfModuleDispose')
external void _jsfModuleDispose(JSString runtimeId);

@JS('__jsfCreateRealm')
external JSObject _jsfCreateRealm(JSString id);
@JS('__jsfCallback')
external JSObject _jsfCallback(JSFunction callback, JSObject realm);
@JS('__jsfUnwrapFuture')
external JSPromise<JSAny?> _jsfUnwrapFuture(JSPromise<JSAny?> promise);

@JS('__jsfInstallDiagnostics')
external void _jsfInstallDiagnostics(JSObject realm, JSFunction? log,
    JSFunction? rejection, JSFunction? failure);
