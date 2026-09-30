import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

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
    ffi.Pointer<JSFValue> pointer, {
    bool owned = true,
    Object? owner,
  })  : _owned = owned,
        _owner = owner,
        _state = _ValueState(_bindings, _runtime, pointer, owned) {
    if (_owned) {
      _liveValues
          .putIfAbsent(_runtime.address, () => <_ValueState>{})
          .add(_state);
      _valueFinalizer.attach(this, _state, detach: this);
    }
  }

  final NativeJsfBindings _bindings;
  final ffi.Pointer<JSFRuntime> _runtime;
  final bool _owned;
  final Object? _owner;
  final _ValueState _state;
  ffi.Pointer<JSFValue> get _pointer => _state.pointer;
  set _pointer(ffi.Pointer<JSFValue> value) => _state.pointer = value;

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
        return jsonDecode(_readCString(_bindings.JSF_ValueToJson));
      case jsfValueArrayBuffer:
        return toBytes();
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
      final keyPtr =
          jsonEncode(key).toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _wrapOrThrow(_bindings.JSF_ValueObjectGetJson(_pointer, keyPtr));
    });
  }

  /// Sets an object property by string [key].
  void setPropertyValue(String key, JsValue value) {
    _ensureAlive();
    _checkOwner(value);
    using((arena) {
      final keyPtr =
          jsonEncode(key).toNativeUtf8(allocator: arena).cast<ffi.Char>();
      final result = _bindings.JSF_ValueObjectSetJson(
        _pointer,
        keyPtr,
        value.nativePointer,
      );
      if (result < 0) {
        _throwLastError();
      }
    });
    _notifyJobs();
  }

  /// Reads an array-like item by [index].
  JsValue getIndexValue(int index) {
    _ensureAlive();
    RangeError.checkValueInInterval(index, 0, 4294967294, 'index');
    return _wrapOrThrow(_bindings.JSF_ValueArrayGet(_pointer, index));
  }

  /// Sets an array-like item by [index].
  void setIndexValue(int index, JsValue value) {
    _ensureAlive();
    RangeError.checkValueInInterval(index, 0, 4294967294, 'index');
    _checkOwner(value);
    final result = _bindings.JSF_ValueArraySet(
      _pointer,
      index,
      value.nativePointer,
    );
    if (result < 0) {
      _throwLastError();
    }
    _notifyJobs();
  }

  /// Calls this value as a JavaScript function.
  ///
  /// [thisValue] is used as JavaScript `this` when supplied.
  JsValue callWithValues(List<JsValue> arguments, {JsValue? thisValue}) {
    _ensureAlive();
    if (thisValue != null) _checkOwner(thisValue);
    for (final value in arguments) {
      _checkOwner(value);
    }
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
      _notifyJobs();
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
      _throwLastError();
    }
    try {
      return result.cast<Utf8>().toDartString();
    } finally {
      _bindings.JSF_FreeCString(result);
    }
  }

  void _ensureAlive() {
    if (_state.runtimeDisposed) {
      throw StateError('JavaScript runtime has been disposed.');
    }
    if (_pointer == ffi.nullptr || _runtime == ffi.nullptr) {
      throw StateError('JavaScript value has been disposed.');
    }
  }

  void _checkOwner(JsValue value) {
    value._ensureAlive();
    if (value._runtime != _runtime) {
      throw ArgumentError('JavaScript value belongs to a different runtime.');
    }
  }

  void _notifyJobs() {
    final owner = _owner;
    if (owner is NativeRuntimeOwner) owner.schedulePendingJobs();
  }

  void _unregister() {
    if (!_owned) {
      return;
    }
    final values = _liveValues[_runtime.address];
    _valueFinalizer.detach(this);
    values?.remove(_state);
    if (values != null && values.isEmpty) {
      _liveValues.remove(_runtime.address);
    }
  }

  /// Copies an ArrayBuffer without expanding its bytes into transfer JSON.
  Uint8List toBytes() {
    _ensureAlive();
    return using((arena) {
      final length = arena<ffi.Size>();
      final data = _bindings.JSF_ValueArrayBufferData(_pointer, length);
      if (data == ffi.nullptr && length.value != 0) _throwLastError();
      return length.value == 0
          ? Uint8List(0)
          : Uint8List.fromList(data.asTypedList(length.value));
    });
  }

  Never _throwLastError() {
    final json = _bindings.JSF_RuntimeLastErrorJson(_runtime);
    if (json != ffi.nullptr) {
      throw JsException.fromDetails(
          jsonDecode(json.cast<Utf8>().toDartString()));
    }
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
    _notifyJobs();
    return wrapJsValue(_bindings, _runtime, pointer, owner: _owner);
  }
}

class _ValueState {
  _ValueState(this.bindings, this.runtime, this.pointer, this.owned);
  final NativeJsfBindings bindings;
  final ffi.Pointer<JSFRuntime> runtime;
  final bool owned;
  ffi.Pointer<JSFValue> pointer;
  bool runtimeDisposed = false;
  void free() {
    if (pointer != ffi.nullptr && owned) bindings.JSF_ValueFree(pointer);
    pointer = ffi.nullptr;
  }
}

final _valueFinalizer = Finalizer<_ValueState>((state) {
  state.free();
  final values = _liveValues[state.runtime.address];
  values?.remove(state);
  if (values != null && values.isEmpty) {
    _liveValues.remove(state.runtime.address);
  }
});

void disposeRuntimeValues(ffi.Pointer<JSFRuntime> runtime) {
  final values = _liveValues.remove(runtime.address);
  if (values == null) return;
  for (final state in values) {
    state.runtimeDisposed = true;
    state.free();
  }
}

final Map<int, Set<_ValueState>> _liveValues = {};

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
