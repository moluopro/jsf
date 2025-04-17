/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

/// An abstract class that defines the interface for a runtime environment
/// capable of evaluating and executing code, as well as managing resources.
abstract class Runtime {
  /// Evaluates the given [code] and returns the result as a [String].
  ///
  /// This method is typically used for expressions or code that produces
  /// a return value. Implementations should handle errors appropriately.
  String eval(String code);

  /// Executes an initialization script [code] within the runtime.
  ///
  /// This method is intended for running setup or configuration code
  /// before any evaluations. It does not return a value.
  void execInitScript(String code);

  /// Releases any resources held by the runtime.
  ///
  /// After calling [dispose], the runtime should no longer be used.
  void dispose();
}
