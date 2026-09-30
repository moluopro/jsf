import 'exception.dart';

/// Console output delivered without parsing formatted strings.
class JsConsoleEvent {
  JsConsoleEvent(this.level, List<Object?> arguments)
      : arguments = List.unmodifiable(arguments),
        time = DateTime.now();
  final String level;
  final List<Object?> arguments;
  final DateTime time;
}

/// Platform features that applications can test before invoking an API.
class JsRuntimeCapabilities {
  const JsRuntimeCapabilities(
      {required this.engine,
      required this.engineVersion,
      required this.abiVersion,
      required this.memoryLimits,
      required this.executionTimeout,
      required this.backgroundExecution,
      required this.fetch,
      this.isolatedGlobals = true});
  final String engine;
  final String engineVersion;
  final int? abiVersion;
  final bool memoryLimits,
      executionTimeout,
      backgroundExecution,
      fetch,
      isolatedGlobals;
}

/// An explicit snapshot; collecting engine memory statistics can traverse its heap.
class JsRuntimeStatistics {
  const JsRuntimeStatistics(
      {this.memoryUsedBytes,
      this.allocatedBytes,
      required this.liveHandles,
      required this.registeredCallbacks,
      required this.registeredModuleBytes,
      required this.pendingFutures,
      required this.pendingTimers,
      required this.activeRequests});
  final int? memoryUsedBytes, allocatedBytes;
  final int liveHandles, registeredCallbacks, registeredModuleBytes;
  final int? pendingFutures, pendingTimers, activeRequests;
}

/// Invalidates a host callback, including JavaScript references to its old function.
class JsCallbackRegistration {
  JsCallbackRegistration(void Function() unregister) : _unregister = unregister;
  void Function()? _unregister;
  bool get isDisposed => _unregister == null;
  void dispose() {
    final unregister = _unregister;
    _unregister = null;
    unregister?.call();
  }
}

typedef JsErrorHandler = void Function(JsException error);
