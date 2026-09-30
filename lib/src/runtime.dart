/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

import 'diagnostics.dart';

/// An abstract class that defines the interface for a runtime environment
/// capable of evaluating and executing code, as well as managing resources.
abstract class Runtime {
  /// Evaluates the given JavaScript [code] and returns the result.
  ///
  /// Implementations should provide logic to execute the code in the
  /// appropriate context and convert the result into a Dart-compatible value.
  dynamic eval(String code, {String filename = '<eval>', bool module = false});

  /// Calls a JavaScript function expression with Dart values converted to JS.
  dynamic call(String functionRef, [List<Object?> arguments = const []]);

  /// Assigns a Dart value to `globalThis[name]` in the JavaScript context.
  void setGlobal(String name, Object? value);

  /// Executes a JavaScript initialization script.
  ///
  /// This method is typically used to load environment setup code,
  /// such as helper functions or libraries, before actual evaluation.
  void execInitScript(String code);

  /// Frees any resources held by the runtime, such as contexts or memory.
  ///
  /// This should be called when the runtime is no longer in use to prevent
  /// resource leaks and ensure proper cleanup.
  void dispose();
}

/// Complete managed-runtime contract, preserving the smaller [Runtime] interface.
abstract interface class JsRuntimeApi<V> implements Runtime {
  Future<dynamic> evalAsync(String code,
      {String filename = '<eval>', bool module = false, Duration? timeout});
  V evalValue(String code, {String filename = '<eval>', bool module = false});
  V callValue(V function, [List<Object?> arguments = const []]);
  Future<dynamic> awaitValue(V value, {Duration? timeout});
  V newValue(Object? value);
  V getGlobalValue(String name);
  JsCallbackRegistration registerFunction(
      String name, Object? Function(List<Object?> arguments) callback);
  JsCallbackRegistration registerHandleFunction(
      String name, Object? Function(List<V> arguments) callback);
  bool unregisterFunction(String name);
  void loadModule(String name, String source);
  V loadModuleValue(String name, String source);
  void registerModule(String name, String source);
  void registerModules(Map<String, String> modules);
  void registerImportMap(Map<String, String> imports);
  void clearModules();
  int executePendingJobs();
  void setMemoryLimit(int bytes);
  void setMaxStackSize(int bytes);
  void setTimeout(Duration timeout);
  void clearTimeout();
  JsRuntimeCapabilities get capabilities;
  JsRuntimeStatistics get statistics;
}
