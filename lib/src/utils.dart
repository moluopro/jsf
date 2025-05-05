import 'jsf_bindings.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Parses a raw JavaScript result based on its tag and returns the
/// corresponding Dart representation.
///
/// [context] - The JSContext used during evaluation.
/// [rawResult] - The JSValue returned from JS evaluation.
/// [bindings] - The bindings to QuickJS functions.
///
/// Returns a Dart representation of the JS value (e.g. int, double, String, BigInt, bool, or null).
dynamic parseRawResult(
    ffi.Pointer<JSContext> context, JSValue rawResult, JsfBindings bindings) {
  switch (rawResult.tag) {
    case JS_TAG_INT:
      return _parseInt32(context, rawResult, bindings);

    case JS_TAG_BIG_INT:
      return _parseBigInt(context, rawResult, bindings);

    case JS_TAG_FLOAT64:
      return _parseFloat64(context, rawResult, bindings);

    case JS_TAG_BOOL:
      return bindings.JS_ToBool(context, rawResult) != 0;

    case JS_TAG_NULL:
    case JS_TAG_UNDEFINED:
    case JS_TAG_EXCEPTION:
      return null;

    // case JS_TAG_EXCEPTION:
    //   throw Exception("JS evaluation resulted in an exception");

    case JS_TAG_STRING:
    // return _parseString(context, rawResult, bindings);

    default:
      // throw Exception("Unknown JS tag: \${rawResult.tag}");
      return _parseString(context, rawResult, bindings);
  }
}

/// Parses a JSValue containing a 32-bit integer.
///
/// Returns an [int] value.
int _parseInt32(
    ffi.Pointer<JSContext> context, JSValue rawResult, JsfBindings bindings) {
  return using((arena) {
    final intPtr = arena<ffi.Int32>();
    final retCode = bindings.JS_ToInt32(context, intPtr, rawResult);
    if (retCode != 0) {
      throw Exception("JS_ToInt32 failed");
    }
    return intPtr.value;
  });
}

/// Parses a JSValue containing a BigInt represented as a string.
///
/// Returns a [BigInt] or null if parsing fails.
BigInt? _parseBigInt(
    ffi.Pointer<JSContext> context, JSValue rawResult, JsfBindings bindings) {
  final jsStrValue = bindings.JS_ToString(context, rawResult);
  final dartStr = _toDartString(context, jsStrValue, bindings);
  return BigInt.tryParse(dartStr);
}

/// Parses a JSValue containing a 64-bit float.
///
/// Returns a [double] value.
double _parseFloat64(
    ffi.Pointer<JSContext> context, JSValue rawResult, JsfBindings bindings) {
  return using((arena) {
    final doublePtr = arena<ffi.Double>();
    final retCode = bindings.JS_ToFloat64(context, doublePtr, rawResult);
    if (retCode != 0) {
      throw Exception("JS_ToFloat64 failed");
    }
    return doublePtr.value;
  });
}

/// Parses a JSValue containing a string.
///
/// Returns a [String] value.
String _parseString(
    ffi.Pointer<JSContext> context, JSValue rawResult, JsfBindings bindings) {
  final jsStrValue = bindings.JS_ToString(context, rawResult);
  return _toDartString(context, jsStrValue, bindings);
}

/// Converts a JS string to a Dart string using QuickJS's JS_ToCStringLen2.
///
/// [context] - The JS execution context.
/// [jsStrValue] - The JSValue containing the string.
/// [bindings] - The JS function bindings.
///
/// Returns a Dart [String].
String _toDartString(
    ffi.Pointer<JSContext> context, JSValue jsStrValue, JsfBindings bindings) {
  return using((arena) {
    final lengthPtr = arena<ffi.Size>();
    final cStrPtr =
        bindings.JS_ToCStringLen2(context, lengthPtr, jsStrValue, 0);

    if (cStrPtr == ffi.nullptr) {
      throw Exception("JS_ToCStringLen2 failed");
    }

    final dartStr = cStrPtr.cast<Utf8>().toDartString();
    bindings.JS_FreeCString(context, cStrPtr);
    return dartStr;
  });
}
