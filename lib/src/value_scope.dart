import 'value.dart' if (dart.library.js_interop) 'value_web.dart';

/// Owns a group of handles until the scope is disposed.
class JsValueScope {
  final Set<JsValue> _values = {};
  bool _disposed = false;
  JsValue own(JsValue value) {
    if (_disposed) throw StateError('Value scope has been disposed.');
    if (!value.isOwned || value.isDisposed) {
      throw ArgumentError('Expected a live owned handle.');
    }
    _values.add(value);
    return value;
  }

  /// Transfers a handle out of this scope; its caller must dispose it.
  JsValue release(JsValue value) {
    if (!_values.remove(value)) {
      throw ArgumentError('Handle is not owned by this scope.');
    }
    return value;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final value in _values) {
      value.dispose();
    }
    _values.clear();
  }
}

/// Releases all tracked handles after a synchronous operation, including throws.
T withJsValues<T>(T Function(JsValueScope scope) operation) {
  final scope = JsValueScope();
  try {
    return operation(scope);
  } finally {
    scope.dispose();
  }
}

/// Keeps tracked handles alive until the asynchronous operation completes.
Future<T> withJsValuesAsync<T>(
    Future<T> Function(JsValueScope scope) operation) async {
  final scope = JsValueScope();
  try {
    return await operation(scope);
  } finally {
    scope.dispose();
  }
}
