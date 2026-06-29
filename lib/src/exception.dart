/// Exception thrown when JavaScript evaluation, conversion, or interop fails.
class JsException implements Exception {
  /// Creates a JavaScript exception wrapper with a human-readable [message].
  JsException(this.message);

  /// Error message reported by JSF or QuickJS.
  final String message;

  @override
  String toString() => 'JsException: $message';
}
