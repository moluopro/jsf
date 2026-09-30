/// Structured failure from evaluation, conversion or a host callback.
class JsException implements Exception {
  JsException(this.message, {this.name = 'Error', this.stack, this.cause});
  final String name;
  final String message;
  final String? stack;
  final Object? cause;

  factory JsException.fromDetails(Object? details) {
    if (details is Map) {
      return JsException(
          details['message']?.toString() ?? 'JavaScript exception',
          name: details['name']?.toString() ?? 'Error',
          stack: details['stack'] as String?,
          cause: details['cause']);
    }
    if (details is List) {
      return JsException(details.whereType<String>().join('\n'));
    }
    return JsException(details.toString());
  }
  @override
  String toString() =>
      'JsException: $name: $message${stack == null ? '' : '\n$stack'}';
}
