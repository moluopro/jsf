// ignore_for_file: non_constant_identifier_names

import 'dart:ffi' as ffi;

/// Internal notification for JavaScript jobs queued by handle operations.
abstract class NativeRuntimeOwner {
  void schedulePendingJobs();
}

final class JSFRuntime extends ffi.Opaque {}

final class JSFValue extends ffi.Opaque {}

typedef _AllocArrayBufferNative = ffi.Pointer<JSFValue> Function(
    ffi.Pointer<JSFRuntime>, ffi.Size, ffi.Pointer<ffi.Pointer<ffi.Uint8>>);
typedef _AllocArrayBufferDart = ffi.Pointer<JSFValue> Function(
    ffi.Pointer<JSFRuntime>, int, ffi.Pointer<ffi.Pointer<ffi.Uint8>>);

typedef DartFunctionNative = ffi.Pointer<ffi.Char> Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Char>,
);

typedef DartFreeNative = ffi.Void Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Char>,
);

typedef DartHandleFunctionNative = ffi.Pointer<JSFValue> Function(
  ffi.Pointer<ffi.Void>,
  ffi.Pointer<ffi.Pointer<JSFValue>>,
  ffi.Int32,
);

class NativeJsfBindings {
  NativeJsfBindings(ffi.DynamicLibrary library)
      : _lookup = library.lookup,
        JSF_RuntimeFreePtr = library.lookup('JSF_RuntimeFree'),
        JSF_ValueFreePtr = library.lookup('JSF_ValueFree') {
    if (!library.providesSymbol('JSF_ABIVersion') || JSF_ABIVersion() != 2) {
      throw StateError(
          'JSF native ABI mismatch: expected ABI 2. Rebuild the native library shipped with jsf 1.2.0.');
    }
  }

  late final JSF_ABIVersion =
      _lookup<ffi.NativeFunction<ffi.Int32 Function()>>('JSF_ABIVersion')
          .asFunction<int Function()>();
  late final JSF_EngineVersion =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
              'JSF_EngineVersion')
          .asFunction<ffi.Pointer<ffi.Char> Function()>();
  late final JSF_ValueNewExceptionJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueNewExceptionJson')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_RuntimeSetRejectionTracking = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<JSFRuntime>,
                  ffi.Int32)>>('JSF_RuntimeSetRejectionTracking')
      .asFunction<void Function(ffi.Pointer<JSFRuntime>, int)>();
  late final JSF_RuntimeTakeRejection = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_RuntimeTakeRejection')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>)>();
  late final JSF_ValueObservePromise =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueObservePromise')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();
  late final JSF_RuntimeUnregisterCallback = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Void>)>>('JSF_RuntimeUnregisterCallback')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Void>)>();
  late final JSF_RuntimeStatistics = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_RuntimeStatistics')
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFRuntime>)>();

  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  final ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSFRuntime>)>>
      JSF_RuntimeFreePtr;

  final ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSFValue>)>>
      JSF_ValueFreePtr;

  late final JSF_RuntimeNew =
      _lookup<ffi.NativeFunction<ffi.Pointer<JSFRuntime> Function()>>(
              'JSF_RuntimeNew')
          .asFunction<ffi.Pointer<JSFRuntime> Function()>();

  late final JSF_RuntimeFree =
      JSF_RuntimeFreePtr.asFunction<void Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeSetMemoryLimit = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<JSFRuntime>,
                  ffi.Size)>>('JSF_RuntimeSetMemoryLimit')
      .asFunction<void Function(ffi.Pointer<JSFRuntime>, int)>();

  late final JSF_RuntimeSetMaxStackSize = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<JSFRuntime>,
                  ffi.Size)>>('JSF_RuntimeSetMaxStackSize')
      .asFunction<void Function(ffi.Pointer<JSFRuntime>, int)>();

  late final JSF_RuntimeSetTimeout = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<JSFRuntime>, ffi.Int32)>>('JSF_RuntimeSetTimeout')
      .asFunction<void Function(ffi.Pointer<JSFRuntime>, int)>();

  late final JSF_RuntimeClearTimeout =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSFRuntime>)>>(
              'JSF_RuntimeClearTimeout')
          .asFunction<void Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeExecutePendingJobs =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFRuntime>)>>(
              'JSF_RuntimeExecutePendingJobs')
          .asFunction<int Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeLastError = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_RuntimeLastError')
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeLastErrorJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_RuntimeLastErrorJson')
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeRegisterModule = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>)>>('JSF_RuntimeRegisterModule')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>();

  late final JSF_RuntimeRegisterModuleAlias = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>)>>('JSF_RuntimeRegisterModuleAlias')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>();

  late final JSF_RuntimeClearModules =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSFRuntime>)>>(
              'JSF_RuntimeClearModules')
          .asFunction<void Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_RuntimeResolveDartFuture = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Int32,
                  ffi.Pointer<ffi.Char>,
                  ffi.Int32)>>('JSF_RuntimeResolveDartFuture')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>, int, ffi.Pointer<ffi.Char>, int)>();

  late final JSF_Eval = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Int32)>>('JSF_Eval')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, int)>();

  late final JSF_LoadModule = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>)>>('JSF_LoadModule')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  late final JSF_GetGlobal = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_GetGlobal')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_GetGlobalJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_GetGlobalJson')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_SetGlobal = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<JSFValue>)>>('JSF_SetGlobal')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<JSFValue>)>();

  late final JSF_SetGlobalJson = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<JSFValue>)>>('JSF_SetGlobalJson')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<JSFValue>)>();

  late final JSF_Call = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<JSFValue>,
                  ffi.Pointer<JSFValue>,
                  ffi.Pointer<ffi.Pointer<JSFValue>>,
                  ffi.Int32)>>('JSF_Call')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<JSFValue>,
              ffi.Pointer<JSFValue>,
              ffi.Pointer<ffi.Pointer<JSFValue>>,
              int)>();

  late final JSF_CallGlobal = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Pointer<JSFValue>>,
                  ffi.Int32)>>('JSF_CallGlobal')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Pointer<JSFValue>>,
              int)>();

  late final JSF_RegisterDartFunction = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.NativeFunction<DartFunctionNative>>,
                  ffi.Pointer<ffi.NativeFunction<DartFreeNative>>,
                  ffi.Pointer<ffi.Void>)>>('JSF_RegisterDartFunction')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.NativeFunction<DartFunctionNative>>,
              ffi.Pointer<ffi.NativeFunction<DartFreeNative>>,
              ffi.Pointer<ffi.Void>)>();

  late final JSF_RegisterDartFunctionJson = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.NativeFunction<DartFunctionNative>>,
                  ffi.Pointer<ffi.NativeFunction<DartFreeNative>>,
                  ffi.Pointer<ffi.Void>)>>('JSF_RegisterDartFunctionJson')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.NativeFunction<DartFunctionNative>>,
              ffi.Pointer<ffi.NativeFunction<DartFreeNative>>,
              ffi.Pointer<ffi.Void>)>();

  late final JSF_RegisterDartHandleFunction = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.NativeFunction<DartHandleFunctionNative>>,
                  ffi.Pointer<ffi.Void>)>>('JSF_RegisterDartHandleFunction')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.NativeFunction<DartHandleFunctionNative>>,
              ffi.Pointer<ffi.Void>)>();

  late final JSF_RegisterDartHandleFunctionJson = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.NativeFunction<DartHandleFunctionNative>>,
                  ffi.Pointer<ffi.Void>)>>('JSF_RegisterDartHandleFunctionJson')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.NativeFunction<DartHandleFunctionNative>>,
              ffi.Pointer<ffi.Void>)>();

  late final JSF_ValueNewUndefined = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_ValueNewUndefined')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_ValueNewNull = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_ValueNewNull')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_ValueNewBool = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>, ffi.Int32)>>('JSF_ValueNewBool')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>, int)>();

  late final JSF_ValueNewInt64 = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>, ffi.Int64)>>('JSF_ValueNewInt64')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>, int)>();

  late final JSF_ValueNewFloat64 = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>, ffi.Double)>>('JSF_ValueNewFloat64')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>, double)>();

  late final JSF_ValueNewString = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueNewString')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueNewBigInt = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueNewBigInt')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueNewJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueNewJson')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueNewTransferJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueNewTransferJson')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueNewArray = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_ValueNewArray')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_ValueNewObject = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>)>>('JSF_ValueNewObject')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>)>();

  late final JSF_ValueFree =
      JSF_ValueFreePtr.asFunction<void Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueDup = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFValue>)>>('JSF_ValueDup')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueType =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueType')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueToBool =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueToBool')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueToInt64 =
      _lookup<ffi.NativeFunction<ffi.Int64 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueToInt64')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueToFloat64 =
      _lookup<ffi.NativeFunction<ffi.Double Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueToFloat64')
          .asFunction<double Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueToCString = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  ffi.Pointer<JSFValue>)>>('JSF_ValueToCString')
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueToJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  ffi.Pointer<JSFValue>)>>('JSF_ValueToJson')
      .asFunction<ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueArrayLength =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValueArrayLength')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValueArrayGet = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFValue>, ffi.Uint32)>>('JSF_ValueArrayGet')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFValue>, int)>();

  late final JSF_ValueArraySet = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFValue>, ffi.Uint32,
                  ffi.Pointer<JSFValue>)>>('JSF_ValueArraySet')
      .asFunction<
          int Function(ffi.Pointer<JSFValue>, int, ffi.Pointer<JSFValue>)>();

  late final JSF_ValueObjectGet = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFValue>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueObjectGet')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueObjectGetJson = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFValue>,
                  ffi.Pointer<ffi.Char>)>>('JSF_ValueObjectGetJson')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>)>();

  late final JSF_ValueObjectSet = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<JSFValue>)>>('JSF_ValueObjectSet')
      .asFunction<
          int Function(ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<JSFValue>)>();

  late final JSF_ValueObjectSetJson = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>,
                  ffi.Pointer<JSFValue>)>>('JSF_ValueObjectSetJson')
      .asFunction<
          int Function(ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<JSFValue>)>();

  late final JSF_ValuePromiseState =
      _lookup<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<JSFValue>)>>(
              'JSF_ValuePromiseState')
          .asFunction<int Function(ffi.Pointer<JSFValue>)>();

  late final JSF_ValuePromiseResult = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFValue>)>>('JSF_ValuePromiseResult')
      .asFunction<ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFValue>)>();

  late final JSF_FreeCString =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Char>)>>(
              'JSF_FreeCString')
          .asFunction<void Function(ffi.Pointer<ffi.Char>)>();
  late final JSF_RuntimeExecutePendingJobsMax = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(ffi.Pointer<JSFRuntime>,
                  ffi.Int32)>>('JSF_RuntimeExecutePendingJobsMax')
      .asFunction<int Function(ffi.Pointer<JSFRuntime>, int)>();
  late final JSF_ValueNewArrayBuffer = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Uint8>, ffi.Size)>>('JSF_ValueNewArrayBuffer')
      .asFunction<
          ffi.Pointer<JSFValue> Function(
              ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Uint8>, int)>();
  // Older libraries retain the existing copy path. Resolve only once.
  late final JSF_ValueAllocArrayBuffer = _lookupAllocArrayBuffer();

  _AllocArrayBufferDart? _lookupAllocArrayBuffer() {
    try {
      return _lookup<ffi.NativeFunction<_AllocArrayBufferNative>>(
              'JSF_ValueAllocArrayBuffer')
          .asFunction<_AllocArrayBufferDart>();
    } on ArgumentError {
      return null;
    }
  }

  late final JSF_ValueArrayBufferData = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<JSFValue>,
                  ffi.Pointer<ffi.Size>)>>('JSF_ValueArrayBufferData')
      .asFunction<
          ffi.Pointer<ffi.Uint8> Function(
              ffi.Pointer<JSFValue>, ffi.Pointer<ffi.Size>)>();
  late final JSF_RuntimeResolveDartFutureValue = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Int32,
                  ffi.Pointer<JSFValue>,
                  ffi.Int32)>>('JSF_RuntimeResolveDartFutureValue')
      .asFunction<
          int Function(
              ffi.Pointer<JSFRuntime>, int, ffi.Pointer<JSFValue>, int)>();

  late final JSF_EvalLen = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Size,
                  ffi.Pointer<ffi.Char>,
                  ffi.Int32)>>('JSF_EvalLen')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>, int, ffi.Pointer<ffi.Char>, int)>();
  late final JSF_LoadModuleLen = _lookup<
          ffi.NativeFunction<
              ffi.Pointer<JSFValue> Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Size)>>('JSF_LoadModuleLen')
      .asFunction<
          ffi.Pointer<JSFValue> Function(ffi.Pointer<JSFRuntime>,
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, int)>();
  late final JSF_RuntimeRegisterModuleLen = _lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  ffi.Pointer<JSFRuntime>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Pointer<ffi.Char>,
                  ffi.Size)>>('JSF_RuntimeRegisterModuleLen')
      .asFunction<
          int Function(ffi.Pointer<JSFRuntime>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>, int)>();
}

const int jsfValueUndefined = 0;
const int jsfValueNull = 1;
const int jsfValueBool = 2;
const int jsfValueInt = 3;
const int jsfValueFloat = 4;
const int jsfValueBigInt = 5;
const int jsfValueString = 6;
const int jsfValueArray = 7;
const int jsfValueObject = 8;
const int jsfValueFunction = 9;
const int jsfValuePromise = 10;
const int jsfValueArrayBuffer = 11;

const int jsfPromisePending = 0;
const int jsfPromiseFulfilled = 1;
const int jsfPromiseRejected = 2;
