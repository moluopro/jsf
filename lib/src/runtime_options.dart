/// Configuration applied when creating a [JsRuntime].
///
/// Native platforms enforce these options through QuickJS where possible.
/// Flutter Web uses the browser JavaScript runtime, so resource limits are
/// reported as unsupported and do not interrupt normal execution.
class JsRuntimeOptions {
  /// Creates runtime options.
  const JsRuntimeOptions({
    this.memoryLimitBytes,
    this.maxStackSizeBytes,
    this.timeout,
  });

  /// Maximum heap size allowed for the native QuickJS runtime, in bytes.
  final int? memoryLimitBytes;

  /// Maximum native JavaScript stack size, in bytes.
  final int? maxStackSizeBytes;

  /// Maximum synchronous JavaScript execution time before interruption.
  final Duration? timeout;
}
