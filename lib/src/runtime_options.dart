import 'fetch.dart';
import 'diagnostics.dart';

/// Configuration applied when creating a [JsRuntime].
///
/// Native platforms enforce these options through QuickJS where possible.
/// Flutter Web uses the browser JavaScript runtime. Native heap, stack and
/// execution budgets throw UnsupportedError there; browser timers and jobs
/// remain managed by the browser.
class JsRuntimeOptions {
  /// Creates runtime options.
  const JsRuntimeOptions({
    this.memoryLimitBytes,
    this.maxStackSizeBytes,
    this.timeout,
    this.fetch,
    this.maxTimers = 1024,
    this.maxCallbacks = 4096,
    this.maxPendingFutures = 4096,
    this.maxModuleSourceBytes = 16 * 1024 * 1024,
    this.jobBatchSize = 64,
    this.onConsole,
    this.onUnhandledRejection,
    this.onError,
  });

  /// Maximum heap size allowed for the native QuickJS runtime, in bytes.
  final int? memoryLimitBytes;

  /// Maximum native JavaScript stack size, in bytes.
  final int? maxStackSizeBytes;

  /// Maximum synchronous JavaScript execution time before interruption.
  final Duration? timeout;

  /// Enables bounded Fetch on native platforms. Null leaves network access disabled.
  /// Web continues to use browser fetch.
  final JsFetchOptions? fetch;

  final int maxTimers, maxCallbacks, maxPendingFutures, maxModuleSourceBytes;

  /// Maximum Promise jobs per event-loop turn.
  final int jobBatchSize;
  final void Function(JsConsoleEvent event)? onConsole;
  final JsErrorHandler? onUnhandledRejection;
  final JsErrorHandler? onError;

  void validate() {
    for (final limit in [
      maxTimers,
      maxCallbacks,
      maxPendingFutures,
      maxModuleSourceBytes,
      jobBatchSize
    ]) {
      if (limit <= 0) {
        throw ArgumentError('Runtime host limits must be positive.');
      }
    }
    if ((memoryLimitBytes != null && memoryLimitBytes! <= 0) ||
        (maxStackSizeBytes != null && maxStackSizeBytes! <= 0) ||
        (timeout != null &&
            (timeout!.inMicroseconds <= 0 ||
                timeout!.inMicroseconds > 2147483647000))) {
      throw ArgumentError('Invalid runtime memory, stack or execution budget.');
    }
    fetch?.validate();
  }
}
