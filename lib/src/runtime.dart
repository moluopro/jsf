/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

/// An abstract class that defines the interface for a runtime environment
/// capable of evaluating and executing code, as well as managing resources.
abstract class Runtime {
  /// Evaluates the given JavaScript [code] and returns the result.
  ///
  /// Implementations should provide logic to execute the code in the
  /// appropriate context and convert the result into a Dart-compatible value.
  dynamic eval(String code);

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
