import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

/// Sentinel used when a Dart value represents JavaScript `undefined`.
const jsUndefined = JsUndefined();

/// Sentinel used when a JavaScript sparse array contains a hole.
const jsArrayHole = JsArrayHole();

/// Sentinel representing JavaScript `undefined`.
class JsUndefined {
  /// Creates the singleton-compatible `undefined` sentinel.
  const JsUndefined();

  @override
  String toString() => 'undefined';
}

/// Sentinel representing a missing element in a sparse JavaScript array.
class JsArrayHole {
  /// Creates the singleton-compatible sparse array hole sentinel.
  const JsArrayHole();

  @override
  String toString() => '<array hole>';
}

/// Serializable representation of a JavaScript `RegExp`.
class JsRegExp {
  /// Creates a JavaScript regular expression descriptor.
  const JsRegExp(this.source, this.flags);

  /// Regular expression source without surrounding slashes.
  final String source;

  /// JavaScript flags, such as `g`, `i`, `m`, or `u`.
  final String flags;

  @override
  String toString() => '/$source/$flags';

  @override
  bool operator ==(Object other) =>
      other is JsRegExp && other.source == source && other.flags == flags;

  @override
  int get hashCode => Object.hash(source, flags);
}

/// Structured details extracted from a JavaScript or Dart callback error.
class JsErrorDetails {
  /// Creates an error descriptor.
  const JsErrorDetails({
    required this.name,
    required this.message,
    this.stack,
  });

  /// JavaScript error name, for example `Error` or `TypeError`.
  final String name;

  /// Error message.
  final String message;

  /// Optional stack trace text.
  final String? stack;

  @override
  String toString() => '$name: $message';

  @override
  bool operator ==(Object other) =>
      other is JsErrorDetails &&
      other.name == name &&
      other.message == message &&
      other.stack == stack;

  @override
  int get hashCode => Object.hash(name, message, stack);
}

/// Serializable representation of a JavaScript TypedArray.
class JsTypedArray {
  /// Creates a typed array descriptor.
  const JsTypedArray(this.name, this.values);

  /// JavaScript constructor name, for example `Uint8Array`.
  final String name;

  /// Values copied from the typed array, including BigInt and nonfinite numbers.
  final List<Object?> values;

  @override
  String toString() => '$name(${values.length})';

  @override
  bool operator ==(Object other) =>
      other is JsTypedArray &&
      other.name == name &&
      _listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(values));
}

/// A snapshot of a JavaScript DataView's visible bytes.
class JsDataView {
  JsDataView(List<int> bytes) : bytes = Uint8List.fromList(bytes);
  final Uint8List bytes;
  @override
  String toString() => 'DataView(${bytes.length})';
}

/// Marker returned when a JavaScript value cannot be represented as a Dart
/// value snapshot.
class JsUnsupportedValue {
  /// Creates an unsupported-value marker.
  const JsUnsupportedValue(this.type, [this.value]);

  /// JavaScript value category, such as `Function` or `Symbol`.
  final String type;

  /// Optional debug representation supplied by the JavaScript side.
  final Object? value;

  @override
  String toString() => value == null ? type : '$type($value)';
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

/// Decodes a JSF transfer-schema value into Dart objects.
Object? decodeJsTransferValue(Object? value) {
  if (value is List) {
    return value.map(decodeJsTransferValue).toList(growable: false);
  }
  if (value is Map) {
    final type = value[r'$jsf.type'];
    switch (type) {
      case 'Object':
        return {
          for (final entry in value['entries'] as List)
            entry[0] as String: decodeJsTransferValue(entry[1])
        };
      case 'DataView':
        return JsDataView((value['bytes'] as List).cast<int>());
      case 'Undefined':
        return jsUndefined;
      case 'ArrayHole':
        return jsArrayHole;
      case 'BigInt':
        return BigInt.parse(value['value'] as String);
      case 'Number':
        return _decodeNumber(value['value'] as String);
      case 'Date':
        return DateTime.parse(value['value'] as String);
      case 'RegExp':
        return JsRegExp(
          value['source'] as String? ?? '',
          value['flags'] as String? ?? '',
        );
      case 'Error':
        return JsErrorDetails(
          name: value['name'] as String? ?? 'Error',
          message: value['message'] as String? ?? '',
          stack: value['stack'] as String?,
        );
      case 'Map':
        final entries = (value['entries'] as List? ?? const []);
        return Map<Object?, Object?>.fromEntries(
          entries.map((entry) {
            final pair = entry as List;
            return MapEntry(
              decodeJsTransferValue(pair[0]),
              decodeJsTransferValue(pair[1]),
            );
          }),
        );
      case 'Set':
        return (value['values'] as List? ?? const [])
            .map(decodeJsTransferValue)
            .toSet();
      case 'ArrayBuffer':
        return Uint8List.fromList(
          (value['bytes'] as List? ?? const []).cast<int>(),
        );
      case 'TypedArray':
        return JsTypedArray(
          value['name'] as String? ?? 'TypedArray',
          (value['values'] as List? ?? const [])
              .map(decodeJsTransferValue)
              .toList(),
        );
      case 'Symbol':
      case 'Function':
        return JsUnsupportedValue(type as String, value['value']);
      case 'DartError':
        return JsErrorDetails(
          name: 'DartError',
          message: value['message'] as String? ?? '',
        );
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), decodeJsTransferValue(item)),
    );
  }
  return value;
}

/// Encodes a Dart object into JSF's transfer schema.
///
/// This is a snapshot conversion. Use `JsValue` handles when JavaScript object
/// identity, prototypes, functions, or host objects must be preserved.
Object? encodeJsTransferValue(Object? value) =>
    _TransferEncoder().encode(value);

class _TransferEncoder {
  final Set<Object> _active = HashSet.identity();
  Object? encode(Object? value) {
    final tracked = value is Iterable || value is Map;
    if (tracked && !_active.add(value!)) {
      throw ArgumentError(
          'Circular Dart value; use JsValue handles for object identity.');
    }
    try {
      return _encode(value);
    } finally {
      if (tracked) _active.remove(value);
    }
  }

  Object? _encode(Object? value) {
    if (value == null || value is bool || value is String) {
      return value;
    }
    if (value is int) {
      if (value > 9007199254740991 || value < -9007199254740991) {
        return {r'$jsf.type': 'BigInt', 'value': value.toString()};
      }
      return value;
    }
    if (value is double) {
      if (value.isNaN) {
        return {r'$jsf.type': 'Number', 'value': 'NaN'};
      }
      if (value == double.infinity) {
        return {r'$jsf.type': 'Number', 'value': 'Infinity'};
      }
      if (value == double.negativeInfinity) {
        return {r'$jsf.type': 'Number', 'value': '-Infinity'};
      }
      if (value == 0 && value.isNegative) {
        return {r'$jsf.type': 'Number', 'value': '-0'};
      }
      return value;
    }
    if (value is JsUndefined) {
      return {r'$jsf.type': 'Undefined'};
    }
    if (value is JsArrayHole) {
      return {r'$jsf.type': 'ArrayHole'};
    }
    if (value is BigInt) {
      return {r'$jsf.type': 'BigInt', 'value': value.toString()};
    }
    if (value is DateTime) {
      return {
        r'$jsf.type': 'Date',
        'value': value.toUtc().toIso8601String(),
      };
    }
    if (value is JsRegExp) {
      return {
        r'$jsf.type': 'RegExp',
        'source': value.source,
        'flags': value.flags
      };
    }
    if (value is JsErrorDetails) {
      return {
        r'$jsf.type': 'Error',
        'name': value.name,
        'message': value.message,
        if (value.stack != null) 'stack': value.stack,
      };
    }
    if (value is JsDataView) {
      return {r'$jsf.type': 'DataView', 'bytes': value.bytes.toList()};
    }
    if (value is Uint8List) {
      return {r'$jsf.type': 'ArrayBuffer', 'bytes': value.toList()};
    }
    if (value is JsTypedArray) {
      return {
        r'$jsf.type': 'TypedArray',
        'name': value.name,
        'values': value.values.map(encode).toList(),
      };
    }
    if (value is Set) {
      return {
        r'$jsf.type': 'Set',
        'values': value.map(encode).toList(growable: false),
      };
    }
    if (value is Iterable) {
      return value.map(encode).toList(growable: false);
    }
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        return {
          r'$jsf.type': 'Map',
          'entries': value.entries
              .map((e) => [encode(e.key), encode(e.value)])
              .toList()
        };
      }
      if (value.containsKey(r'$jsf.type')) {
        return {
          r'$jsf.type': 'Object',
          'entries': value.entries.map((e) => [e.key, encode(e.value)]).toList()
        };
      }
      return value.map((key, item) => MapEntry(key as String, encode(item)));
    }
    throw ArgumentError.value(
      value,
      'value',
      'Unsupported JavaScript interop value type: ${value.runtimeType}.',
    );
  }
}

/// Encodes [value] as a JavaScript-compatible JSON transfer literal.
String toJavaScriptLiteral(Object? value) {
  return jsonEncode(encodeJsTransferValue(value));
}

Object? _decodeNumber(String value) {
  switch (value) {
    case 'NaN':
      return double.nan;
    case 'Infinity':
      return double.infinity;
    case '-Infinity':
      return double.negativeInfinity;
    case '-0':
      return -0.0;
  }
  return double.parse(value);
}
