import 'dart:convert';
import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import 'conversion.dart';
import 'exception.dart';
import 'native_bindings.dart';

/// Handle to a JavaScript value owned by, or borrowed from, a [JsRuntime].
///
/// Owned handles must be released with [dispose] when no longer needed.
/// Borrowed handles are only valid for the callback where they were received.
class JsValue {
  JsValue._(
    this._bindings,
    this._runtime,
    this._pointer, {
    bool owned = true,
    Object? owner,
  })  : _owned = owned,
        _owner = owner {
    if (_owned) {
      _liveValues.putIfAbsent(_runtime.address, () => <JsValue>{}).add(this);
    }
  }

  final NativeJsfBindings _bindings;
  final ffi.Pointer<JSFRuntime> _runtime;
  final bool _owned;
  final Object? _owner;
  ffi.Pointer<JSFValue> _pointer;
  bool _runtimeDisposed = false;

  /// Whether this handle has already been disposed or released.
  bool get isDisposed => _pointer == ffi.nullptr;

  /// Whether this handle owns the native JavaScript value reference.
  bool get isOwned => _owned;

  /// Native pointer used internally by JSF's FFI layer.
  ffi.Pointer<JSFValue> get nativePointer {
    _ensureAlive();
    return _pointer;
  }

  /// Native runtime pointer used internally by JSF's FFI layer.
  ffi.Pointer<JSFRuntime> get nativeRuntime {
    _ensureAlive();
    return _runtime;
  }

  /// JSF value type tag.
  int get type {
    _ensureAlive();
    return _bindings.JSF_ValueType(_pointer);
  }

  /// Converts this JavaScript value to a Dart snapshot.
  ///
  /// Object identity, prototypes, functions, and host objects are not
  /// preserved. Keep this [JsValue] and use handle APIs when identity matters.
  dynamic toDart() {
    _ensureAlive();
    switch (type) {
      case jsfValueUndefined:
        return jsUndefined;
      case jsfValueNull:
        return null;
      case jsfValueBool:
        return _bindings.JSF_ValueToBool(_pointer) != 0;
      case jsfValueInt:
        return _bindings.JSF_ValueToInt64(_pointer);
      case jsfValueFloat:
        return _bindings.JSF_ValueToFloat64(_pointer);
      case jsfValueBigInt:
        return BigInt.parse(_readCString(_bindings.JSF_ValueToCString));
      case jsfValueString:
        return _readCString(_bindings.JSF_ValueToCString);
      case jsfValueArray:
      case jsfValueObject:
      case jsfValueFunction:
      case jsfValuePromise:
        final jsonText = _readCString(_bindings.JSF_ValueToJson);
        return decodeJsTransferValue(jsonDecode(jsonText));
      default:
        return _readCString(_bindings.JSF_ValueToCString);
    }
  }

  /// Converts this value to JSF's transfer JSON schema.
  String toJson() {
    _ensureAlive();
    return _readCString(_bindings.JSF_ValueToJson);
  }

  /// Array-like length, or `0` for non-array values.
  int get length {
    _ensureAlive();
    final result = _bindings.JSF_ValueArrayLength(_pointer);
    if (result < 0) {
      _throwLastError();
    }
    return result;
  }

  /// Creates an owned duplicate of this handle.
  JsValue duplicate() {
    _ensureAlive();
    return wrapJsValue(
      _bindings,
      _runtime,
      _bindings.JSF_ValueDup(_pointer),
      owner: _owner,
    );
  }

  /// Reads an object property by string [key].
  JsValue getPropertyValue(String key) {
    _ensureAlive();
    return using((arena) {
      final keyPtr = key.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(_bindings.JSF_ValueObjectGet(_pointer, keyPtr));
    });
  }

  /// Sets an object property by string [key].
  void setPropertyValue(String key, JsValue value) {
    _ensureAlive();
    value._ensureAlive();
    using((arena) {
      final keyPtr = key.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final result = _bindings.JSF_ValueObjectSet(
        _pointer,
        keyPtr,
        value.nativePointer,
      );
      if (result < 0) {
        _throwLastError();
      }
    });
  }

  /// Reads an array-like item by [index].
  JsValue getIndexValue(int index) {
    _ensureAlive();
    return _wrapOrThrow(_bindings.JSF_ValueArrayGet(_pointer, index));
  }

  /// Sets an array-like item by [index].
  void setIndexValue(int index, JsValue value) {
    _ensureAlive();
    value._ensureAlive();
    final result = _bindings.JSF_ValueArraySet(
      _pointer,
      index,
      value.nativePointer,
    );
    if (result < 0) {
      _throwLastError();
    }
  }

  /// Calls this value as a JavaScript function.
  ///
  /// [thisValue] is used as JavaScript `this` when supplied.
  JsValue callWithValues(List<JsValue> arguments, {JsValue? thisValue}) {
    _ensureAlive();
    final argv = calloc<ffi.Pointer<JSFValue>>(arguments.length);
    try {
      for (var i = 0; i < arguments.length; i++) {
        argv[i] = arguments[i].nativePointer;
      }
      return _wrapOrThrow(
        _bindings.JSF_Call(
          _runtime,
          _pointer,
          thisValue?.nativePointer ?? ffi.nullptr,
          argv,
          arguments.length,
        ),
      );
    } finally {
      calloc.free(argv);
    }
  }

  /// Promise state for JavaScript Promise values.
  int get promiseState {
    _ensureAlive();
    final result = _bindings.JSF_ValuePromiseState(_pointer);
    if (result < 0) {
      _throwLastError();
    }
    return result;
  }

  /// Promise fulfillment value or rejection reason.
  JsValue promiseResult() {
    _ensureAlive();
    return _wrapOrThrow(_bindings.JSF_ValuePromiseResult(_pointer));
  }

  /// Transfers ownership of the native pointer to native code.
  ///
  /// After this call the Dart handle is disposed and must not be used again.
  ffi.Pointer<JSFValue> releaseNativePointer() {
    _ensureAlive();
    final pointer = _pointer;
    _unregister();
    _pointer = ffi.nullptr;
    return pointer;
  }

  /// Releases this handle.
  void dispose() {
    if (_pointer == ffi.nullptr) {
      return;
    }
    if (_owned) {
      _bindings.JSF_ValueFree(_pointer);
    }
    _unregister();
    _pointer = ffi.nullptr;
  }

  String _readCString(
    ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFValue>) read,
  ) {
    final result = read(_pointer);
    if (result == ffi.nullptr) {
      throw JsException('Unable to convert JavaScript value.');
    }
    try {
      return result.cast<Utf8>().toDartString();
    } finally {
      _bindings.JSF_FreeCString(result);
    }
  }

  void _ensureAlive() {
    if (_runtimeDisposed) {
      throw StateError('JavaScript runtime has been disposed.');
    }
    if (_pointer == ffi.nullptr || _runtime == ffi.nullptr) {
      throw StateError('JavaScript value has been disposed.');
    }
  }

  void _unregister() {
    if (!_owned) {
      return;
    }
    final values = _liveValues[_runtime.address];
    values?.remove(this);
    if (values != null && values.isEmpty) {
      _liveValues.remove(_runtime.address);
    }
  }

  Never _throwLastError() {
    final error = _bindings.JSF_RuntimeLastError(_runtime);
    if (error == ffi.nullptr) {
      throw JsException('Unknown JavaScript error.');
    }
    throw JsException(error.cast<Utf8>().toDartString());
  }

  JsValue _wrapOrThrow(ffi.Pointer<JSFValue> pointer) {
    if (pointer == ffi.nullptr) {
      _throwLastError();
    }
    return wrapJsValue(_bindings, _runtime, pointer, owner: _owner);
  }
}

void disposeRuntimeValues(ffi.Pointer<JSFRuntime> runtime) {
  final values = _liveValues.remove(runtime.address);
  if (values == null) {
    return;
  }
  for (final value in List<JsValue>.from(values)) {
    value._runtimeDisposed = true;
    if (value._pointer != ffi.nullptr && value._owned) {
      value._bindings.JSF_ValueFree(value._pointer);
      value._pointer = ffi.nullptr;
    }
  }
}

final Map<int, Set<JsValue>> _liveValues = <int, Set<JsValue>>{};

JsValue wrapJsValue(
  NativeJsfBindings bindings,
  ffi.Pointer<JSFRuntime> runtime,
  ffi.Pointer<JSFValue> pointer, {
  Object? owner,
}) {
  if (pointer == ffi.nullptr) {
    throw JsException('Native JavaScript value allocation failed.');
  }
  return JsValue._(bindings, runtime, pointer, owner: owner);
}

JsValue wrapBorrowedJsValue(
  NativeJsfBindings bindings,
  ffi.Pointer<JSFRuntime> runtime,
  ffi.Pointer<JSFValue> pointer, {
  Object? owner,
}) {
  if (pointer == ffi.nullptr) {
    throw JsException('Native JavaScript value allocation failed.');
  }
  return JsValue._(bindings, runtime, pointer, owned: false, owner: owner);
}
