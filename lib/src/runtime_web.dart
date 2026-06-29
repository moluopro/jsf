/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'conversion.dart';
import 'runtime.dart';
import 'runtime_options.dart';
import 'value_web.dart';

/// Browser JavaScript runtime used by Flutter Web.
///
/// This implementation mirrors the native API where the browser platform
/// allows it. Native resource limits and native ES module hooks are reported as
/// unsupported instead of interrupting normal application code.
class JsRuntime implements Runtime {
  /// Creates a browser-backed JavaScript runtime.
  JsRuntime({JsRuntimeOptions options = const JsRuntimeOptions()}) {
    ensureJsWebHelpers();
    if (options.memoryLimitBytes != null ||
        options.maxStackSizeBytes != null ||
        options.timeout != null) {
      _warn('Runtime limits are not enforceable on web.');
    }
  }

  final Set<String> _registeredCallbackNames = <String>{};
  final Set<Object> _registeredCallbacks = <Object>{};
  final String _moduleRuntimeId = 'jsf_web_${_nextRuntimeId++}';
  int _nextCallbackId = 1;
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
    final value = module
        ? JsValue(_jsfModuleEvalAsync(
            _moduleRuntimeId.toJS,
            code.toJS,
            filename.toJS,
          ))
        : evalValue(code, filename: filename);
    try {
      return await awaitValue(value, timeout: timeout);
    } finally {
      value.dispose();
    }
  }

  /// Evaluates JavaScript and returns a browser-backed [JsValue].
  JsValue evalValue(
    String code, {
    String filename = '<eval>',
    bool module = false,
  }) {
    _ensureAlive();
    if (module) {
      return JsValue(_jsfModuleEval(
        _moduleRuntimeId.toJS,
        code.toJS,
        filename.toJS,
      ));
    }
    return JsValue(_jsfEval(
      _moduleRuntimeId.toJS,
      code.toJS,
      filename.toJS,
    ));
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
    final values = arguments.map((value) => JsValue(webValueFromDart(value)));
    return function.callWithValues(values.toList(growable: false));
  }

  /// Assigns a Dart value to `globalThis[name]`.
  @override
  void setGlobal(String name, Object? value) {
    _ensureAlive();
    globalContext[name] = webValueFromDart(value);
  }

  /// Reads `globalThis[name]` as a [JsValue] handle.
  JsValue getGlobalValue(String name) {
    _ensureAlive();
    return JsValue(globalContext[name]);
  }

  /// Converts a Dart value into a JavaScript value handle.
  JsValue newValue(Object? value) {
    _ensureAlive();
    if (value is JsValue) {
      return value.duplicate();
    }
    return JsValue(webValueFromDart(value));
  }

  /// Awaits a JavaScript Promise-like value and converts its result to Dart.
  Future<dynamic> awaitValue(
    JsValue value, {
    Duration? timeout,
  }) async {
    _ensureAlive();
    final future = jsPromiseResolve(value.nativeValue)
        .toDart
        .then<dynamic>((resolved) => webValueToDart(resolved));
    if (timeout == null) {
      return future;
    }
    return Future.any<dynamic>([
      future,
      Future<dynamic>.delayed(
        timeout,
        () => throw TimeoutException(
          'JavaScript promise timed out after $timeout.',
        ),
      ),
    ]);
  }

  /// Registers a Dart callback as `globalThis[name]`.
  void registerFunction(
    String name,
    Object? Function(List<Object?> arguments) callback,
  ) {
    _ensureAlive();
    final hiddenName = '__jsf_dart_callback_${_nextCallbackId++}';
    JSAny? invoke(JSAny? jsArgs) {
      try {
        final args = webValueToDart(jsArgs);
        final result = callback(
          args is List ? args.cast<Object?>() : const <Object?>[],
        );
        return _toJsCallbackResult(result);
      } catch (error) {
        return webValueFromDart(
          JsErrorDetails(name: 'DartError', message: error.toString()),
        );
      }
    }

    final function = invoke.toJS;
    _registeredCallbacks.add(function);
    globalContext[hiddenName] = function;
    jsEval(
      ('globalThis[${jsonEncode(name)}]=(...args)=>'
              'globalThis[${jsonEncode(hiddenName)}](args)')
          .toJS,
    );
    _registeredCallbackNames.add(name);
    _registeredCallbackNames.add(hiddenName);
  }

  /// Registers a Dart callback that receives [JsValue] handles.
  void registerHandleFunction(
    String name,
    Object? Function(List<JsValue> arguments) callback,
  ) {
    _ensureAlive();
    final hiddenName = '__jsf_dart_handle_callback_${_nextCallbackId++}';
    JSAny? invoke(JSAny? jsArgs) {
      try {
        final args = <JsValue>[];
        final length = jsArgs == null ? 0 : JsValue(jsArgs).length;
        for (var i = 0; i < length; i++) {
          args.add(JsValue(jsArgs).getIndexValue(i));
        }
        final result = callback(args);
        if (result is JsValue) {
          return result.nativeValue;
        }
        return _toJsCallbackResult(result);
      } catch (error) {
        return webValueFromDart(
          JsErrorDetails(name: 'DartError', message: error.toString()),
        );
      }
    }

    final function = invoke.toJS;
    _registeredCallbacks.add(function);
    globalContext[hiddenName] = function;
    jsEval(
      ('globalThis[${jsonEncode(name)}]=(...args)=>'
              'globalThis[${jsonEncode(hiddenName)}](args)')
          .toJS,
    );
    _registeredCallbackNames.add(name);
    _registeredCallbackNames.add(hiddenName);
  }

  /// Executes pending jobs.
  ///
  /// Browser Promise jobs are owned by the browser event loop, so this is a
  /// no-op on web.
  int executePendingJobs() => 0;

  /// Reports that native memory limits are not enforceable on web.
  void setMemoryLimit(int bytes) {
    _warn('setMemoryLimit is not enforceable on web.');
  }

  /// Reports that native stack limits are not enforceable on web.
  void setMaxStackSize(int bytes) {
    _warn('setMaxStackSize is not enforceable on web.');
  }

  /// Reports that synchronous browser eval timeouts are not enforceable.
  void setTimeout(Duration timeout) {
    _warn('setTimeout is not enforceable for synchronous browser eval.');
  }

  /// Clears timeout settings.
  void clearTimeout() {}

  /// Registers and best-effort evaluates a module source.
  void loadModule(String moduleName, String moduleSource) {
    registerModule(moduleName, moduleSource);
    _jsfModuleLoad(_moduleRuntimeId.toJS, moduleName.toJS);
  }

  /// Registers an in-memory module source.
  void registerModule(String moduleName, String moduleSource) {
    _ensureAlive();
    _jsfModuleRegister(
      _moduleRuntimeId.toJS,
      moduleName.toJS,
      moduleSource.toJS,
    );
  }

  /// Registers multiple in-memory module sources.
  void registerModules(Map<String, String> modules) {
    modules.forEach(registerModule);
  }

  /// Registers import aliases for best-effort web module resolution.
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
  void clearModules() {
    _ensureAlive();
    _jsfModuleClear(_moduleRuntimeId.toJS);
  }

  /// Executes initialization code and discards the result.
  @override
  void execInitScript(String code) {
    _ensureAlive();
    jsEval(code.toJS);
  }

  /// Releases registered browser callback wrappers and module metadata.
  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    for (final name in _registeredCallbackNames) {
      jsEval('delete globalThis[${jsonEncode(name)}]'.toJS);
    }
    _registeredCallbackNames.clear();
    _registeredCallbacks.clear();
    _jsfModuleDispose(_moduleRuntimeId.toJS);
    _disposed = true;
  }

  JSAny? _toJsCallbackResult(Object? result) {
    if (result is Future) {
      return result.then<JSAny?>((value) => webValueFromDart(value)).toJS;
    }
    return webValueFromDart(result);
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('JavaScript runtime has been disposed.');
    }
  }

  void _warn(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('JSF web: $message');
    }
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
