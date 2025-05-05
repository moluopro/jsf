// ignore_for_file: always_specify_types, unused_field, unused_element
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `jsf`.
///
class JsfBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  JsfBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  JsfBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  ffi.Pointer<JSRuntime> JS_NewRuntime() {
    return _JS_NewRuntime();
  }

  late final _JS_NewRuntimePtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<JSRuntime> Function()>>(
          'JS_NewRuntime');
  late final _JS_NewRuntime =
      _JS_NewRuntimePtr.asFunction<ffi.Pointer<JSRuntime> Function()>();

  /// info lifetime must exceed that of rt
  void JS_SetRuntimeInfo(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Char> info,
  ) {
    return _JS_SetRuntimeInfo(
      rt,
      info,
    );
  }

  late final _JS_SetRuntimeInfoPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<ffi.Char>)>>('JS_SetRuntimeInfo');
  late final _JS_SetRuntimeInfo = _JS_SetRuntimeInfoPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Char>)>();

  void JS_SetMemoryLimit(
    ffi.Pointer<JSRuntime> rt,
    int limit,
  ) {
    return _JS_SetMemoryLimit(
      rt,
      limit,
    );
  }

  late final _JS_SetMemoryLimitPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, ffi.Size)>>(
      'JS_SetMemoryLimit');
  late final _JS_SetMemoryLimit = _JS_SetMemoryLimitPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  void JS_SetGCThreshold(
    ffi.Pointer<JSRuntime> rt,
    int gc_threshold,
  ) {
    return _JS_SetGCThreshold(
      rt,
      gc_threshold,
    );
  }

  late final _JS_SetGCThresholdPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, ffi.Size)>>(
      'JS_SetGCThreshold');
  late final _JS_SetGCThreshold = _JS_SetGCThresholdPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  /// use 0 to disable maximum stack size check
  void JS_SetMaxStackSize(
    ffi.Pointer<JSRuntime> rt,
    int stack_size,
  ) {
    return _JS_SetMaxStackSize(
      rt,
      stack_size,
    );
  }

  late final _JS_SetMaxStackSizePtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, ffi.Size)>>(
      'JS_SetMaxStackSize');
  late final _JS_SetMaxStackSize = _JS_SetMaxStackSizePtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  /// should be called when changing thread to update the stack top value
  /// used to check stack overflow.
  void JS_UpdateStackTop(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_UpdateStackTop(
      rt,
    );
  }

  late final _JS_UpdateStackTopPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>)>>(
          'JS_UpdateStackTop');
  late final _JS_UpdateStackTop =
      _JS_UpdateStackTopPtr.asFunction<void Function(ffi.Pointer<JSRuntime>)>();

  ffi.Pointer<JSRuntime> JS_NewRuntime2(
    ffi.Pointer<JSMallocFunctions> mf,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_NewRuntime2(
      mf,
      opaque,
    );
  }

  late final _JS_NewRuntime2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSRuntime> Function(ffi.Pointer<JSMallocFunctions>,
              ffi.Pointer<ffi.Void>)>>('JS_NewRuntime2');
  late final _JS_NewRuntime2 = _JS_NewRuntime2Ptr.asFunction<
      ffi.Pointer<JSRuntime> Function(
          ffi.Pointer<JSMallocFunctions>, ffi.Pointer<ffi.Void>)>();

  void JS_FreeRuntime(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_FreeRuntime(
      rt,
    );
  }

  late final _JS_FreeRuntimePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>)>>(
          'JS_FreeRuntime');
  late final _JS_FreeRuntime =
      _JS_FreeRuntimePtr.asFunction<void Function(ffi.Pointer<JSRuntime>)>();

  ffi.Pointer<ffi.Void> JS_GetRuntimeOpaque(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_GetRuntimeOpaque(
      rt,
    );
  }

  late final _JS_GetRuntimeOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSRuntime>)>>('JS_GetRuntimeOpaque');
  late final _JS_GetRuntimeOpaque = _JS_GetRuntimeOpaquePtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSRuntime>)>();

  void JS_SetRuntimeOpaque(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetRuntimeOpaque(
      rt,
      opaque,
    );
  }

  late final _JS_SetRuntimeOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<ffi.Void>)>>('JS_SetRuntimeOpaque');
  late final _JS_SetRuntimeOpaque = _JS_SetRuntimeOpaquePtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Void>)>();

  void JS_MarkValue(
    ffi.Pointer<JSRuntime> rt,
    JSValue val,
    ffi.Pointer<JS_MarkFunc> mark_func,
  ) {
    return _JS_MarkValue(
      rt,
      val,
      mark_func,
    );
  }

  late final _JS_MarkValuePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSRuntime>, JSValue,
              ffi.Pointer<JS_MarkFunc>)>>('JS_MarkValue');
  late final _JS_MarkValue = _JS_MarkValuePtr.asFunction<
      void Function(
          ffi.Pointer<JSRuntime>, JSValue, ffi.Pointer<JS_MarkFunc>)>();

  void JS_RunGC(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_RunGC(
      rt,
    );
  }

  late final _JS_RunGCPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>)>>(
          'JS_RunGC');
  late final _JS_RunGC =
      _JS_RunGCPtr.asFunction<void Function(ffi.Pointer<JSRuntime>)>();

  int JS_IsLiveObject(
    ffi.Pointer<JSRuntime> rt,
    JSValue obj,
  ) {
    return _JS_IsLiveObject(
      rt,
      obj,
    );
  }

  late final _JS_IsLiveObjectPtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSRuntime>, JSValue)>>(
      'JS_IsLiveObject');
  late final _JS_IsLiveObject = _JS_IsLiveObjectPtr.asFunction<
      int Function(ffi.Pointer<JSRuntime>, JSValue)>();

  ffi.Pointer<JSContext> JS_NewContext(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_NewContext(
      rt,
    );
  }

  late final _JS_NewContextPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSContext> Function(
              ffi.Pointer<JSRuntime>)>>('JS_NewContext');
  late final _JS_NewContext = _JS_NewContextPtr.asFunction<
      ffi.Pointer<JSContext> Function(ffi.Pointer<JSRuntime>)>();

  void JS_FreeContext(
    ffi.Pointer<JSContext> s,
  ) {
    return _JS_FreeContext(
      s,
    );
  }

  late final _JS_FreeContextPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_FreeContext');
  late final _JS_FreeContext =
      _JS_FreeContextPtr.asFunction<void Function(ffi.Pointer<JSContext>)>();

  ffi.Pointer<JSContext> JS_DupContext(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_DupContext(
      ctx,
    );
  }

  late final _JS_DupContextPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSContext> Function(
              ffi.Pointer<JSContext>)>>('JS_DupContext');
  late final _JS_DupContext = _JS_DupContextPtr.asFunction<
      ffi.Pointer<JSContext> Function(ffi.Pointer<JSContext>)>();

  ffi.Pointer<ffi.Void> JS_GetContextOpaque(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_GetContextOpaque(
      ctx,
    );
  }

  late final _JS_GetContextOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSContext>)>>('JS_GetContextOpaque');
  late final _JS_GetContextOpaque = _JS_GetContextOpaquePtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>)>();

  void JS_SetContextOpaque(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetContextOpaque(
      ctx,
      opaque,
    );
  }

  late final _JS_SetContextOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Void>)>>('JS_SetContextOpaque');
  late final _JS_SetContextOpaque = _JS_SetContextOpaquePtr.asFunction<
      void Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<JSRuntime> JS_GetRuntime(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_GetRuntime(
      ctx,
    );
  }

  late final _JS_GetRuntimePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSRuntime> Function(
              ffi.Pointer<JSContext>)>>('JS_GetRuntime');
  late final _JS_GetRuntime = _JS_GetRuntimePtr.asFunction<
      ffi.Pointer<JSRuntime> Function(ffi.Pointer<JSContext>)>();

  void JS_SetClassProto(
    ffi.Pointer<JSContext> ctx,
    int class_id,
    JSValue obj,
  ) {
    return _JS_SetClassProto(
      ctx,
      class_id,
      obj,
    );
  }

  late final _JS_SetClassProtoPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSContext>, JSClassID, JSValue)>>('JS_SetClassProto');
  late final _JS_SetClassProto = _JS_SetClassProtoPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, int, JSValue)>();

  JSValue JS_GetClassProto(
    ffi.Pointer<JSContext> ctx,
    int class_id,
  ) {
    return _JS_GetClassProto(
      ctx,
      class_id,
    );
  }

  late final _JS_GetClassProtoPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSClassID)>>(
      'JS_GetClassProto');
  late final _JS_GetClassProto = _JS_GetClassProtoPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  /// the following functions are used to select the intrinsic object to
  /// save memory
  ffi.Pointer<JSContext> JS_NewContextRaw(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_NewContextRaw(
      rt,
    );
  }

  late final _JS_NewContextRawPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSContext> Function(
              ffi.Pointer<JSRuntime>)>>('JS_NewContextRaw');
  late final _JS_NewContextRaw = _JS_NewContextRawPtr.asFunction<
      ffi.Pointer<JSContext> Function(ffi.Pointer<JSRuntime>)>();

  void JS_AddIntrinsicBaseObjects(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicBaseObjects(
      ctx,
    );
  }

  late final _JS_AddIntrinsicBaseObjectsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicBaseObjects');
  late final _JS_AddIntrinsicBaseObjects = _JS_AddIntrinsicBaseObjectsPtr
      .asFunction<void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicDate(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicDate(
      ctx,
    );
  }

  late final _JS_AddIntrinsicDatePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicDate');
  late final _JS_AddIntrinsicDate = _JS_AddIntrinsicDatePtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicEval(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicEval(
      ctx,
    );
  }

  late final _JS_AddIntrinsicEvalPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicEval');
  late final _JS_AddIntrinsicEval = _JS_AddIntrinsicEvalPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicStringNormalize(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicStringNormalize(
      ctx,
    );
  }

  late final _JS_AddIntrinsicStringNormalizePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicStringNormalize');
  late final _JS_AddIntrinsicStringNormalize =
      _JS_AddIntrinsicStringNormalizePtr.asFunction<
          void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicRegExpCompiler(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicRegExpCompiler(
      ctx,
    );
  }

  late final _JS_AddIntrinsicRegExpCompilerPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicRegExpCompiler');
  late final _JS_AddIntrinsicRegExpCompiler = _JS_AddIntrinsicRegExpCompilerPtr
      .asFunction<void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicRegExp(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicRegExp(
      ctx,
    );
  }

  late final _JS_AddIntrinsicRegExpPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicRegExp');
  late final _JS_AddIntrinsicRegExp = _JS_AddIntrinsicRegExpPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicJSON(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicJSON(
      ctx,
    );
  }

  late final _JS_AddIntrinsicJSONPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicJSON');
  late final _JS_AddIntrinsicJSON = _JS_AddIntrinsicJSONPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicProxy(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicProxy(
      ctx,
    );
  }

  late final _JS_AddIntrinsicProxyPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicProxy');
  late final _JS_AddIntrinsicProxy = _JS_AddIntrinsicProxyPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicMapSet(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicMapSet(
      ctx,
    );
  }

  late final _JS_AddIntrinsicMapSetPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicMapSet');
  late final _JS_AddIntrinsicMapSet = _JS_AddIntrinsicMapSetPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicTypedArrays(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicTypedArrays(
      ctx,
    );
  }

  late final _JS_AddIntrinsicTypedArraysPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicTypedArrays');
  late final _JS_AddIntrinsicTypedArrays = _JS_AddIntrinsicTypedArraysPtr
      .asFunction<void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicPromise(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicPromise(
      ctx,
    );
  }

  late final _JS_AddIntrinsicPromisePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicPromise');
  late final _JS_AddIntrinsicPromise = _JS_AddIntrinsicPromisePtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  void JS_AddIntrinsicWeakRef(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_AddIntrinsicWeakRef(
      ctx,
    );
  }

  late final _JS_AddIntrinsicWeakRefPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_AddIntrinsicWeakRef');
  late final _JS_AddIntrinsicWeakRef = _JS_AddIntrinsicWeakRefPtr.asFunction<
      void Function(ffi.Pointer<JSContext>)>();

  JSValue js_string_codePointRange(
    ffi.Pointer<JSContext> ctx,
    JSValue this_val,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _js_string_codePointRange(
      ctx,
      this_val,
      argc,
      argv,
    );
  }

  late final _js_string_codePointRangePtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, ffi.Int,
              ffi.Pointer<JSValue>)>>('js_string_codePointRange');
  late final _js_string_codePointRange =
      _js_string_codePointRangePtr.asFunction<
          JSValue Function(
              ffi.Pointer<JSContext>, JSValue, int, ffi.Pointer<JSValue>)>();

  ffi.Pointer<ffi.Void> js_malloc_rt(
    ffi.Pointer<JSRuntime> rt,
    int size,
  ) {
    return _js_malloc_rt(
      rt,
      size,
    );
  }

  late final _js_malloc_rtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSRuntime>, ffi.Size)>>('js_malloc_rt');
  late final _js_malloc_rt = _js_malloc_rtPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSRuntime>, int)>();

  void js_free_rt(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _js_free_rt(
      rt,
      ptr,
    );
  }

  late final _js_free_rtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Void>)>>('js_free_rt');
  late final _js_free_rt = _js_free_rtPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ffi.Void> js_realloc_rt(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Void> ptr,
    int size,
  ) {
    return _js_realloc_rt(
      rt,
      ptr,
      size,
    );
  }

  late final _js_realloc_rtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<ffi.Void>, ffi.Size)>>('js_realloc_rt');
  late final _js_realloc_rt = _js_realloc_rtPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(
          ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Void>, int)>();

  int js_malloc_usable_size_rt(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _js_malloc_usable_size_rt(
      rt,
      ptr,
    );
  }

  late final _js_malloc_usable_size_rtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Size Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<ffi.Void>)>>('js_malloc_usable_size_rt');
  late final _js_malloc_usable_size_rt =
      _js_malloc_usable_size_rtPtr.asFunction<
          int Function(ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ffi.Void> js_mallocz_rt(
    ffi.Pointer<JSRuntime> rt,
    int size,
  ) {
    return _js_mallocz_rt(
      rt,
      size,
    );
  }

  late final _js_mallocz_rtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSRuntime>, ffi.Size)>>('js_mallocz_rt');
  late final _js_mallocz_rt = _js_mallocz_rtPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSRuntime>, int)>();

  ffi.Pointer<ffi.Void> js_malloc(
    ffi.Pointer<JSContext> ctx,
    int size,
  ) {
    return _js_malloc(
      ctx,
      size,
    );
  }

  late final _js_mallocPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSContext>, ffi.Size)>>('js_malloc');
  late final _js_malloc = _js_mallocPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>, int)>();

  void js_free(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _js_free(
      ctx,
      ptr,
    );
  }

  late final _js_freePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSContext>, ffi.Pointer<ffi.Void>)>>('js_free');
  late final _js_free = _js_freePtr.asFunction<
      void Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ffi.Void> js_realloc(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Void> ptr,
    int size,
  ) {
    return _js_realloc(
      ctx,
      ptr,
      size,
    );
  }

  late final _js_reallocPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Void>, ffi.Size)>>('js_realloc');
  late final _js_realloc = _js_reallocPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Void>, int)>();

  int js_malloc_usable_size(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Void> ptr,
  ) {
    return _js_malloc_usable_size(
      ctx,
      ptr,
    );
  }

  late final _js_malloc_usable_sizePtr = _lookup<
      ffi.NativeFunction<
          ffi.Size Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Void>)>>('js_malloc_usable_size');
  late final _js_malloc_usable_size = _js_malloc_usable_sizePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ffi.Void> js_realloc2(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Void> ptr,
    int size,
    ffi.Pointer<ffi.Size> pslack,
  ) {
    return _js_realloc2(
      ctx,
      ptr,
      size,
      pslack,
    );
  }

  late final _js_realloc2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Void>,
              ffi.Size,
              ffi.Pointer<ffi.Size>)>>('js_realloc2');
  late final _js_realloc2 = _js_realloc2Ptr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>,
          ffi.Pointer<ffi.Void>, int, ffi.Pointer<ffi.Size>)>();

  ffi.Pointer<ffi.Void> js_mallocz(
    ffi.Pointer<JSContext> ctx,
    int size,
  ) {
    return _js_mallocz(
      ctx,
      size,
    );
  }

  late final _js_malloczPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSContext>, ffi.Size)>>('js_mallocz');
  late final _js_mallocz = _js_malloczPtr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>, int)>();

  ffi.Pointer<ffi.Char> js_strdup(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> str,
  ) {
    return _js_strdup(
      ctx,
      str,
    );
  }

  late final _js_strdupPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Char> Function(
              ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>>('js_strdup');
  late final _js_strdup = _js_strdupPtr.asFunction<
      ffi.Pointer<ffi.Char> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  ffi.Pointer<ffi.Char> js_strndup(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> s,
    int n,
  ) {
    return _js_strndup(
      ctx,
      s,
      n,
    );
  }

  late final _js_strndupPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>, ffi.Size)>>('js_strndup');
  late final _js_strndup = _js_strndupPtr.asFunction<
      ffi.Pointer<ffi.Char> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int)>();

  void JS_ComputeMemoryUsage(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<JSMemoryUsage> s,
  ) {
    return _JS_ComputeMemoryUsage(
      rt,
      s,
    );
  }

  late final _JS_ComputeMemoryUsagePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSMemoryUsage>)>>('JS_ComputeMemoryUsage');
  late final _JS_ComputeMemoryUsage = _JS_ComputeMemoryUsagePtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<JSMemoryUsage>)>();

  void JS_DumpMemoryUsage(
    ffi.Pointer<FILE> fp,
    ffi.Pointer<JSMemoryUsage> s,
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_DumpMemoryUsage(
      fp,
      s,
      rt,
    );
  }

  late final _JS_DumpMemoryUsagePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<FILE>, ffi.Pointer<JSMemoryUsage>,
              ffi.Pointer<JSRuntime>)>>('JS_DumpMemoryUsage');
  late final _JS_DumpMemoryUsage = _JS_DumpMemoryUsagePtr.asFunction<
      void Function(ffi.Pointer<FILE>, ffi.Pointer<JSMemoryUsage>,
          ffi.Pointer<JSRuntime>)>();

  int JS_NewAtomLen(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> str,
    int len,
  ) {
    return _JS_NewAtomLen(
      ctx,
      str,
      len,
    );
  }

  late final _JS_NewAtomLenPtr = _lookup<
      ffi.NativeFunction<
          JSAtom Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Size)>>('JS_NewAtomLen');
  late final _JS_NewAtomLen = _JS_NewAtomLenPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int)>();

  int JS_NewAtom(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> str,
  ) {
    return _JS_NewAtom(
      ctx,
      str,
    );
  }

  late final _JS_NewAtomPtr = _lookup<
      ffi.NativeFunction<
          JSAtom Function(
              ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>>('JS_NewAtom');
  late final _JS_NewAtom = _JS_NewAtomPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  int JS_NewAtomUInt32(
    ffi.Pointer<JSContext> ctx,
    int n,
  ) {
    return _JS_NewAtomUInt32(
      ctx,
      n,
    );
  }

  late final _JS_NewAtomUInt32Ptr = _lookup<
          ffi
          .NativeFunction<JSAtom Function(ffi.Pointer<JSContext>, ffi.Uint32)>>(
      'JS_NewAtomUInt32');
  late final _JS_NewAtomUInt32 = _JS_NewAtomUInt32Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, int)>();

  int JS_DupAtom(
    ffi.Pointer<JSContext> ctx,
    int v,
  ) {
    return _JS_DupAtom(
      ctx,
      v,
    );
  }

  late final _JS_DupAtomPtr = _lookup<
          ffi.NativeFunction<JSAtom Function(ffi.Pointer<JSContext>, JSAtom)>>(
      'JS_DupAtom');
  late final _JS_DupAtom =
      _JS_DupAtomPtr.asFunction<int Function(ffi.Pointer<JSContext>, int)>();

  void JS_FreeAtom(
    ffi.Pointer<JSContext> ctx,
    int v,
  ) {
    return _JS_FreeAtom(
      ctx,
      v,
    );
  }

  late final _JS_FreeAtomPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSContext>, JSAtom)>>('JS_FreeAtom');
  late final _JS_FreeAtom =
      _JS_FreeAtomPtr.asFunction<void Function(ffi.Pointer<JSContext>, int)>();

  void JS_FreeAtomRT(
    ffi.Pointer<JSRuntime> rt,
    int v,
  ) {
    return _JS_FreeAtomRT(
      rt,
      v,
    );
  }

  late final _JS_FreeAtomRTPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSRuntime>, JSAtom)>>('JS_FreeAtomRT');
  late final _JS_FreeAtomRT = _JS_FreeAtomRTPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  JSValue JS_AtomToValue(
    ffi.Pointer<JSContext> ctx,
    int atom,
  ) {
    return _JS_AtomToValue(
      ctx,
      atom,
    );
  }

  late final _JS_AtomToValuePtr = _lookup<
          ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSAtom)>>(
      'JS_AtomToValue');
  late final _JS_AtomToValue = _JS_AtomToValuePtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  JSValue JS_AtomToString(
    ffi.Pointer<JSContext> ctx,
    int atom,
  ) {
    return _JS_AtomToString(
      ctx,
      atom,
    );
  }

  late final _JS_AtomToStringPtr = _lookup<
          ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSAtom)>>(
      'JS_AtomToString');
  late final _JS_AtomToString = _JS_AtomToStringPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  ffi.Pointer<ffi.Char> JS_AtomToCString(
    ffi.Pointer<JSContext> ctx,
    int atom,
  ) {
    return _JS_AtomToCString(
      ctx,
      atom,
    );
  }

  late final _JS_AtomToCStringPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Char> Function(
              ffi.Pointer<JSContext>, JSAtom)>>('JS_AtomToCString');
  late final _JS_AtomToCString = _JS_AtomToCStringPtr.asFunction<
      ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSContext>, int)>();

  int JS_ValueToAtom(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_ValueToAtom(
      ctx,
      val,
    );
  }

  late final _JS_ValueToAtomPtr = _lookup<
          ffi.NativeFunction<JSAtom Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_ValueToAtom');
  late final _JS_ValueToAtom = _JS_ValueToAtomPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_NewClassID(
    ffi.Pointer<JSClassID> pclass_id,
  ) {
    return _JS_NewClassID(
      pclass_id,
    );
  }

  late final _JS_NewClassIDPtr =
      _lookup<ffi.NativeFunction<JSClassID Function(ffi.Pointer<JSClassID>)>>(
          'JS_NewClassID');
  late final _JS_NewClassID =
      _JS_NewClassIDPtr.asFunction<int Function(ffi.Pointer<JSClassID>)>();

  /// Returns the class ID if `v` is an object, otherwise returns JS_INVALID_CLASS_ID.
  int JS_GetClassID(
    JSValue v,
  ) {
    return _JS_GetClassID(
      v,
    );
  }

  late final _JS_GetClassIDPtr =
      _lookup<ffi.NativeFunction<JSClassID Function(JSValue)>>('JS_GetClassID');
  late final _JS_GetClassID =
      _JS_GetClassIDPtr.asFunction<int Function(JSValue)>();

  int JS_NewClass(
    ffi.Pointer<JSRuntime> rt,
    int class_id,
    ffi.Pointer<JSClassDef> class_def,
  ) {
    return _JS_NewClass(
      rt,
      class_id,
      class_def,
    );
  }

  late final _JS_NewClassPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSRuntime>, JSClassID,
              ffi.Pointer<JSClassDef>)>>('JS_NewClass');
  late final _JS_NewClass = _JS_NewClassPtr.asFunction<
      int Function(ffi.Pointer<JSRuntime>, int, ffi.Pointer<JSClassDef>)>();

  int JS_IsRegisteredClass(
    ffi.Pointer<JSRuntime> rt,
    int class_id,
  ) {
    return _JS_IsRegisteredClass(
      rt,
      class_id,
    );
  }

  late final _JS_IsRegisteredClassPtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSRuntime>, JSClassID)>>(
      'JS_IsRegisteredClass');
  late final _JS_IsRegisteredClass = _JS_IsRegisteredClassPtr.asFunction<
      int Function(ffi.Pointer<JSRuntime>, int)>();

  JSValue JS_NewBigInt64(
    ffi.Pointer<JSContext> ctx,
    int v,
  ) {
    return _JS_NewBigInt64(
      ctx,
      v,
    );
  }

  late final _JS_NewBigInt64Ptr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, ffi.Int64)>>(
      'JS_NewBigInt64');
  late final _JS_NewBigInt64 = _JS_NewBigInt64Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  JSValue JS_NewBigUint64(
    ffi.Pointer<JSContext> ctx,
    int v,
  ) {
    return _JS_NewBigUint64(
      ctx,
      v,
    );
  }

  late final _JS_NewBigUint64Ptr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>, ffi.Uint64)>>('JS_NewBigUint64');
  late final _JS_NewBigUint64 = _JS_NewBigUint64Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  JSValue JS_Throw(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_Throw(
      ctx,
      obj,
    );
  }

  late final _JS_ThrowPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue)>>('JS_Throw');
  late final _JS_Throw = _JS_ThrowPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  JSValue JS_GetException(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_GetException(
      ctx,
    );
  }

  late final _JS_GetExceptionPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_GetException');
  late final _JS_GetException = _JS_GetExceptionPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>)>();

  int JS_HasException(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_HasException(
      ctx,
    );
  }

  late final _JS_HasExceptionPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<JSContext>)>>(
          'JS_HasException');
  late final _JS_HasException =
      _JS_HasExceptionPtr.asFunction<int Function(ffi.Pointer<JSContext>)>();

  int JS_IsError(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_IsError(
      ctx,
      val,
    );
  }

  late final _JS_IsErrorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>('JS_IsError');
  late final _JS_IsError = _JS_IsErrorPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  void JS_SetUncatchableError(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
    int flag,
  ) {
    return _JS_SetUncatchableError(
      ctx,
      val,
      flag,
    );
  }

  late final _JS_SetUncatchableErrorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Int)>>('JS_SetUncatchableError');
  late final _JS_SetUncatchableError = _JS_SetUncatchableErrorPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, JSValue, int)>();

  void JS_ResetUncatchableError(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_ResetUncatchableError(
      ctx,
    );
  }

  late final _JS_ResetUncatchableErrorPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>)>>(
          'JS_ResetUncatchableError');
  late final _JS_ResetUncatchableError = _JS_ResetUncatchableErrorPtr
      .asFunction<void Function(ffi.Pointer<JSContext>)>();

  JSValue JS_NewError(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_NewError(
      ctx,
    );
  }

  late final _JS_NewErrorPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_NewError');
  late final _JS_NewError =
      _JS_NewErrorPtr.asFunction<JSValue Function(ffi.Pointer<JSContext>)>();

  JSValue JS_ThrowSyntaxError(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> fmt,
  ) {
    return _JS_ThrowSyntaxError(
      ctx,
      fmt,
    );
  }

  late final _JS_ThrowSyntaxErrorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_ThrowSyntaxError');
  late final _JS_ThrowSyntaxError = _JS_ThrowSyntaxErrorPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ThrowTypeError(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> fmt,
  ) {
    return _JS_ThrowTypeError(
      ctx,
      fmt,
    );
  }

  late final _JS_ThrowTypeErrorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_ThrowTypeError');
  late final _JS_ThrowTypeError = _JS_ThrowTypeErrorPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ThrowReferenceError(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> fmt,
  ) {
    return _JS_ThrowReferenceError(
      ctx,
      fmt,
    );
  }

  late final _JS_ThrowReferenceErrorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_ThrowReferenceError');
  late final _JS_ThrowReferenceError = _JS_ThrowReferenceErrorPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ThrowRangeError(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> fmt,
  ) {
    return _JS_ThrowRangeError(
      ctx,
      fmt,
    );
  }

  late final _JS_ThrowRangeErrorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_ThrowRangeError');
  late final _JS_ThrowRangeError = _JS_ThrowRangeErrorPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ThrowInternalError(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> fmt,
  ) {
    return _JS_ThrowInternalError(
      ctx,
      fmt,
    );
  }

  late final _JS_ThrowInternalErrorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_ThrowInternalError');
  late final _JS_ThrowInternalError = _JS_ThrowInternalErrorPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ThrowOutOfMemory(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_ThrowOutOfMemory(
      ctx,
    );
  }

  late final _JS_ThrowOutOfMemoryPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_ThrowOutOfMemory');
  late final _JS_ThrowOutOfMemory = _JS_ThrowOutOfMemoryPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>)>();

  void __JS_FreeValue(
    ffi.Pointer<JSContext> ctx,
    JSValue v,
  ) {
    return ___JS_FreeValue(
      ctx,
      v,
    );
  }

  late final ___JS_FreeValuePtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>, JSValue)>>(
      '__JS_FreeValue');
  late final ___JS_FreeValue = ___JS_FreeValuePtr
      .asFunction<void Function(ffi.Pointer<JSContext>, JSValue)>();

  void __JS_FreeValueRT(
    ffi.Pointer<JSRuntime> rt,
    JSValue v,
  ) {
    return ___JS_FreeValueRT(
      rt,
      v,
    );
  }

  late final ___JS_FreeValueRTPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, JSValue)>>(
      '__JS_FreeValueRT');
  late final ___JS_FreeValueRT = ___JS_FreeValueRTPtr
      .asFunction<void Function(ffi.Pointer<JSRuntime>, JSValue)>();

  int JS_StrictEq(
    ffi.Pointer<JSContext> ctx,
    JSValue op1,
    JSValue op2,
  ) {
    return _JS_StrictEq(
      ctx,
      op1,
      op2,
    );
  }

  late final _JS_StrictEqPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_StrictEq');
  late final _JS_StrictEq = _JS_StrictEqPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  int JS_SameValue(
    ffi.Pointer<JSContext> ctx,
    JSValue op1,
    JSValue op2,
  ) {
    return _JS_SameValue(
      ctx,
      op1,
      op2,
    );
  }

  late final _JS_SameValuePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_SameValue');
  late final _JS_SameValue = _JS_SameValuePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  int JS_SameValueZero(
    ffi.Pointer<JSContext> ctx,
    JSValue op1,
    JSValue op2,
  ) {
    return _JS_SameValueZero(
      ctx,
      op1,
      op2,
    );
  }

  late final _JS_SameValueZeroPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_SameValueZero');
  late final _JS_SameValueZero = _JS_SameValueZeroPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  int JS_ToBool(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_ToBool(
      ctx,
      val,
    );
  }

  late final _JS_ToBoolPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>('JS_ToBool');
  late final _JS_ToBool =
      _JS_ToBoolPtr.asFunction<int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_ToInt32(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Int32> pres,
    JSValue val,
  ) {
    return _JS_ToInt32(
      ctx,
      pres,
      val,
    );
  }

  late final _JS_ToInt32Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int32>,
              JSValue)>>('JS_ToInt32');
  late final _JS_ToInt32 = _JS_ToInt32Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int32>, JSValue)>();

  int JS_ToInt64(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Int64> pres,
    JSValue val,
  ) {
    return _JS_ToInt64(
      ctx,
      pres,
      val,
    );
  }

  late final _JS_ToInt64Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>,
              JSValue)>>('JS_ToInt64');
  late final _JS_ToInt64 = _JS_ToInt64Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>, JSValue)>();

  int JS_ToIndex(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Uint64> plen,
    JSValue val,
  ) {
    return _JS_ToIndex(
      ctx,
      plen,
      val,
    );
  }

  late final _JS_ToIndexPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint64>,
              JSValue)>>('JS_ToIndex');
  late final _JS_ToIndex = _JS_ToIndexPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint64>, JSValue)>();

  int JS_ToFloat64(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Double> pres,
    JSValue val,
  ) {
    return _JS_ToFloat64(
      ctx,
      pres,
      val,
    );
  }

  late final _JS_ToFloat64Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Double>,
              JSValue)>>('JS_ToFloat64');
  late final _JS_ToFloat64 = _JS_ToFloat64Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Double>, JSValue)>();

  /// return an exception if 'val' is a Number
  int JS_ToBigInt64(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Int64> pres,
    JSValue val,
  ) {
    return _JS_ToBigInt64(
      ctx,
      pres,
      val,
    );
  }

  late final _JS_ToBigInt64Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>,
              JSValue)>>('JS_ToBigInt64');
  late final _JS_ToBigInt64 = _JS_ToBigInt64Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>, JSValue)>();

  /// same as JS_ToInt64() but allow BigInt
  int JS_ToInt64Ext(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Int64> pres,
    JSValue val,
  ) {
    return _JS_ToInt64Ext(
      ctx,
      pres,
      val,
    );
  }

  late final _JS_ToInt64ExtPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>,
              JSValue)>>('JS_ToInt64Ext');
  late final _JS_ToInt64Ext = _JS_ToInt64ExtPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Int64>, JSValue)>();

  JSValue JS_NewStringLen(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> str1,
    int len1,
  ) {
    return _JS_NewStringLen(
      ctx,
      str1,
      len1,
    );
  }

  late final _JS_NewStringLenPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Size)>>('JS_NewStringLen');
  late final _JS_NewStringLen = _JS_NewStringLenPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int)>();

  JSValue JS_NewAtomString(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> str,
  ) {
    return _JS_NewAtomString(
      ctx,
      str,
    );
  }

  late final _JS_NewAtomStringPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_NewAtomString');
  late final _JS_NewAtomString = _JS_NewAtomStringPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_ToString(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_ToString(
      ctx,
      val,
    );
  }

  late final _JS_ToStringPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue)>>('JS_ToString');
  late final _JS_ToString = _JS_ToStringPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  JSValue JS_ToPropertyKey(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_ToPropertyKey(
      ctx,
      val,
    );
  }

  late final _JS_ToPropertyKeyPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_ToPropertyKey');
  late final _JS_ToPropertyKey = _JS_ToPropertyKeyPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  ffi.Pointer<ffi.Char> JS_ToCStringLen2(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Size> plen,
    JSValue val1,
    int cesu8,
  ) {
    return _JS_ToCStringLen2(
      ctx,
      plen,
      val1,
      cesu8,
    );
  }

  late final _JS_ToCStringLen2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Char> Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Size>, JSValue, ffi.Int)>>('JS_ToCStringLen2');
  late final _JS_ToCStringLen2 = _JS_ToCStringLen2Ptr.asFunction<
      ffi.Pointer<ffi.Char> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Size>, JSValue, int)>();

  void JS_FreeCString(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> ptr,
  ) {
    return _JS_FreeCString(
      ctx,
      ptr,
    );
  }

  late final _JS_FreeCStringPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>)>>('JS_FreeCString');
  late final _JS_FreeCString = _JS_FreeCStringPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>)>();

  JSValue JS_NewObjectProtoClass(
    ffi.Pointer<JSContext> ctx,
    JSValue proto,
    int class_id,
  ) {
    return _JS_NewObjectProtoClass(
      ctx,
      proto,
      class_id,
    );
  }

  late final _JS_NewObjectProtoClassPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue,
              JSClassID)>>('JS_NewObjectProtoClass');
  late final _JS_NewObjectProtoClass = _JS_NewObjectProtoClassPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, int)>();

  JSValue JS_NewObjectClass(
    ffi.Pointer<JSContext> ctx,
    int class_id,
  ) {
    return _JS_NewObjectClass(
      ctx,
      class_id,
    );
  }

  late final _JS_NewObjectClassPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, ffi.Int)>>(
      'JS_NewObjectClass');
  late final _JS_NewObjectClass = _JS_NewObjectClassPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, int)>();

  JSValue JS_NewObjectProto(
    ffi.Pointer<JSContext> ctx,
    JSValue proto,
  ) {
    return _JS_NewObjectProto(
      ctx,
      proto,
    );
  }

  late final _JS_NewObjectProtoPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_NewObjectProto');
  late final _JS_NewObjectProto = _JS_NewObjectProtoPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  JSValue JS_NewObject(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_NewObject(
      ctx,
    );
  }

  late final _JS_NewObjectPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_NewObject');
  late final _JS_NewObject =
      _JS_NewObjectPtr.asFunction<JSValue Function(ffi.Pointer<JSContext>)>();

  int JS_IsFunction(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_IsFunction(
      ctx,
      val,
    );
  }

  late final _JS_IsFunctionPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>('JS_IsFunction');
  late final _JS_IsFunction = _JS_IsFunctionPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_IsConstructor(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_IsConstructor(
      ctx,
      val,
    );
  }

  late final _JS_IsConstructorPtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_IsConstructor');
  late final _JS_IsConstructor = _JS_IsConstructorPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_SetConstructorBit(
    ffi.Pointer<JSContext> ctx,
    JSValue func_obj,
    int val,
  ) {
    return _JS_SetConstructorBit(
      ctx,
      func_obj,
      val,
    );
  }

  late final _JS_SetConstructorBitPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Int)>>('JS_SetConstructorBit');
  late final _JS_SetConstructorBit = _JS_SetConstructorBitPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int)>();

  JSValue JS_NewArray(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_NewArray(
      ctx,
    );
  }

  late final _JS_NewArrayPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_NewArray');
  late final _JS_NewArray =
      _JS_NewArrayPtr.asFunction<JSValue Function(ffi.Pointer<JSContext>)>();

  int JS_IsArray(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_IsArray(
      ctx,
      val,
    );
  }

  late final _JS_IsArrayPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>('JS_IsArray');
  late final _JS_IsArray = _JS_IsArrayPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  JSValue JS_NewDate(
    ffi.Pointer<JSContext> ctx,
    double epoch_ms,
  ) {
    return _JS_NewDate(
      ctx,
      epoch_ms,
    );
  }

  late final _JS_NewDatePtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Double)>>('JS_NewDate');
  late final _JS_NewDate = _JS_NewDatePtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, double)>();

  JSValue JS_GetPropertyInternal(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    int prop,
    JSValue receiver,
    int throw_ref_error,
  ) {
    return _JS_GetPropertyInternal(
      ctx,
      obj,
      prop,
      receiver,
      throw_ref_error,
    );
  }

  late final _JS_GetPropertyInternalPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, JSAtom, JSValue,
              ffi.Int)>>('JS_GetPropertyInternal');
  late final _JS_GetPropertyInternal = _JS_GetPropertyInternalPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, int, JSValue, int)>();

  JSValue JS_GetPropertyStr(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    ffi.Pointer<ffi.Char> prop,
  ) {
    return _JS_GetPropertyStr(
      ctx,
      this_obj,
      prop,
    );
  }

  late final _JS_GetPropertyStrPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Pointer<ffi.Char>)>>('JS_GetPropertyStr');
  late final _JS_GetPropertyStr = _JS_GetPropertyStrPtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>, JSValue, ffi.Pointer<ffi.Char>)>();

  JSValue JS_GetPropertyUint32(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int idx,
  ) {
    return _JS_GetPropertyUint32(
      ctx,
      this_obj,
      idx,
    );
  }

  late final _JS_GetPropertyUint32Ptr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Uint32)>>('JS_GetPropertyUint32');
  late final _JS_GetPropertyUint32 = _JS_GetPropertyUint32Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, int)>();

  int JS_SetPropertyInternal(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    int prop,
    JSValue val,
    JSValue this_obj,
    int flags,
  ) {
    return _JS_SetPropertyInternal(
      ctx,
      obj,
      prop,
      val,
      this_obj,
      flags,
    );
  }

  late final _JS_SetPropertyInternalPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, JSAtom, JSValue,
              JSValue, ffi.Int)>>('JS_SetPropertyInternal');
  late final _JS_SetPropertyInternal = _JS_SetPropertyInternalPtr.asFunction<
      int Function(
          ffi.Pointer<JSContext>, JSValue, int, JSValue, JSValue, int)>();

  int JS_SetPropertyUint32(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int idx,
    JSValue val,
  ) {
    return _JS_SetPropertyUint32(
      ctx,
      this_obj,
      idx,
      val,
    );
  }

  late final _JS_SetPropertyUint32Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, ffi.Uint32,
              JSValue)>>('JS_SetPropertyUint32');
  late final _JS_SetPropertyUint32 = _JS_SetPropertyUint32Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int, JSValue)>();

  int JS_SetPropertyInt64(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int idx,
    JSValue val,
  ) {
    return _JS_SetPropertyInt64(
      ctx,
      this_obj,
      idx,
      val,
    );
  }

  late final _JS_SetPropertyInt64Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, ffi.Int64,
              JSValue)>>('JS_SetPropertyInt64');
  late final _JS_SetPropertyInt64 = _JS_SetPropertyInt64Ptr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int, JSValue)>();

  int JS_SetPropertyStr(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    ffi.Pointer<ffi.Char> prop,
    JSValue val,
  ) {
    return _JS_SetPropertyStr(
      ctx,
      this_obj,
      prop,
      val,
    );
  }

  late final _JS_SetPropertyStrPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Pointer<ffi.Char>, JSValue)>>('JS_SetPropertyStr');
  late final _JS_SetPropertyStr = _JS_SetPropertyStrPtr.asFunction<
      int Function(
          ffi.Pointer<JSContext>, JSValue, ffi.Pointer<ffi.Char>, JSValue)>();

  int JS_HasProperty(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int prop,
  ) {
    return _JS_HasProperty(
      ctx,
      this_obj,
      prop,
    );
  }

  late final _JS_HasPropertyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSAtom)>>('JS_HasProperty');
  late final _JS_HasProperty = _JS_HasPropertyPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int)>();

  int JS_IsExtensible(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_IsExtensible(
      ctx,
      obj,
    );
  }

  late final _JS_IsExtensiblePtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_IsExtensible');
  late final _JS_IsExtensible = _JS_IsExtensiblePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_PreventExtensions(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_PreventExtensions(
      ctx,
      obj,
    );
  }

  late final _JS_PreventExtensionsPtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_PreventExtensions');
  late final _JS_PreventExtensions = _JS_PreventExtensionsPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_DeleteProperty(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    int prop,
    int flags,
  ) {
    return _JS_DeleteProperty(
      ctx,
      obj,
      prop,
      flags,
    );
  }

  late final _JS_DeletePropertyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, JSAtom,
              ffi.Int)>>('JS_DeleteProperty');
  late final _JS_DeleteProperty = _JS_DeletePropertyPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int, int)>();

  int JS_SetPrototype(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    JSValue proto_val,
  ) {
    return _JS_SetPrototype(
      ctx,
      obj,
      proto_val,
    );
  }

  late final _JS_SetPrototypePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_SetPrototype');
  late final _JS_SetPrototype = _JS_SetPrototypePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  JSValue JS_GetPrototype(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
  ) {
    return _JS_GetPrototype(
      ctx,
      val,
    );
  }

  late final _JS_GetPrototypePtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_GetPrototype');
  late final _JS_GetPrototype = _JS_GetPrototypePtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  int JS_GetOwnPropertyNames(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Pointer<JSPropertyEnum>> ptab,
    ffi.Pointer<ffi.Uint32> plen,
    JSValue obj,
    int flags,
  ) {
    return _JS_GetOwnPropertyNames(
      ctx,
      ptab,
      plen,
      obj,
      flags,
    );
  }

  late final _JS_GetOwnPropertyNamesPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Pointer<JSPropertyEnum>>,
              ffi.Pointer<ffi.Uint32>,
              JSValue,
              ffi.Int)>>('JS_GetOwnPropertyNames');
  late final _JS_GetOwnPropertyNames = _JS_GetOwnPropertyNamesPtr.asFunction<
      int Function(
          ffi.Pointer<JSContext>,
          ffi.Pointer<ffi.Pointer<JSPropertyEnum>>,
          ffi.Pointer<ffi.Uint32>,
          JSValue,
          int)>();

  int JS_GetOwnProperty(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSPropertyDescriptor> desc,
    JSValue obj,
    int prop,
  ) {
    return _JS_GetOwnProperty(
      ctx,
      desc,
      obj,
      prop,
    );
  }

  late final _JS_GetOwnPropertyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<JSPropertyDescriptor>,
              JSValue,
              JSAtom)>>('JS_GetOwnProperty');
  late final _JS_GetOwnProperty = _JS_GetOwnPropertyPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSPropertyDescriptor>,
          JSValue, int)>();

  JSValue JS_Call(
    ffi.Pointer<JSContext> ctx,
    JSValue func_obj,
    JSValue this_obj,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _JS_Call(
      ctx,
      func_obj,
      this_obj,
      argc,
      argv,
    );
  }

  late final _JS_CallPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue, ffi.Int,
              ffi.Pointer<JSValue>)>>('JS_Call');
  late final _JS_Call = _JS_CallPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue, int,
          ffi.Pointer<JSValue>)>();

  JSValue JS_Invoke(
    ffi.Pointer<JSContext> ctx,
    JSValue this_val,
    int atom,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _JS_Invoke(
      ctx,
      this_val,
      atom,
      argc,
      argv,
    );
  }

  late final _JS_InvokePtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, JSAtom, ffi.Int,
              ffi.Pointer<JSValue>)>>('JS_Invoke');
  late final _JS_Invoke = _JS_InvokePtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>, JSValue, int, int, ffi.Pointer<JSValue>)>();

  JSValue JS_CallConstructor(
    ffi.Pointer<JSContext> ctx,
    JSValue func_obj,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _JS_CallConstructor(
      ctx,
      func_obj,
      argc,
      argv,
    );
  }

  late final _JS_CallConstructorPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, ffi.Int,
              ffi.Pointer<JSValue>)>>('JS_CallConstructor');
  late final _JS_CallConstructor = _JS_CallConstructorPtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>, JSValue, int, ffi.Pointer<JSValue>)>();

  JSValue JS_CallConstructor2(
    ffi.Pointer<JSContext> ctx,
    JSValue func_obj,
    JSValue new_target,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _JS_CallConstructor2(
      ctx,
      func_obj,
      new_target,
      argc,
      argv,
    );
  }

  late final _JS_CallConstructor2Ptr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue, ffi.Int,
              ffi.Pointer<JSValue>)>>('JS_CallConstructor2');
  late final _JS_CallConstructor2 = _JS_CallConstructor2Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue, int,
          ffi.Pointer<JSValue>)>();

  int JS_DetectModule(
    ffi.Pointer<ffi.Char> input,
    int input_len,
  ) {
    return _JS_DetectModule(
      input,
      input_len,
    );
  }

  late final _JS_DetectModulePtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<ffi.Char>, ffi.Size)>>(
      'JS_DetectModule');
  late final _JS_DetectModule = _JS_DetectModulePtr.asFunction<
      int Function(ffi.Pointer<ffi.Char>, int)>();

  /// 'input' must be zero terminated i.e. input[input_len] = '\0'.
  JSValue JS_Eval(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> input,
    int input_len,
    ffi.Pointer<ffi.Char> filename,
    int eval_flags,
  ) {
    return _JS_Eval(
      ctx,
      input,
      input_len,
      filename,
      eval_flags,
    );
  }

  late final _JS_EvalPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Size, ffi.Pointer<ffi.Char>, ffi.Int)>>('JS_Eval');
  late final _JS_Eval = _JS_EvalPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int,
          ffi.Pointer<ffi.Char>, int)>();

  /// same as JS_Eval() but with an explicit 'this_obj' parameter
  JSValue JS_EvalThis(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    ffi.Pointer<ffi.Char> input,
    int input_len,
    ffi.Pointer<ffi.Char> filename,
    int eval_flags,
  ) {
    return _JS_EvalThis(
      ctx,
      this_obj,
      input,
      input_len,
      filename,
      eval_flags,
    );
  }

  late final _JS_EvalThisPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>,
              JSValue,
              ffi.Pointer<ffi.Char>,
              ffi.Size,
              ffi.Pointer<ffi.Char>,
              ffi.Int)>>('JS_EvalThis');
  late final _JS_EvalThis = _JS_EvalThisPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, ffi.Pointer<ffi.Char>,
          int, ffi.Pointer<ffi.Char>, int)>();

  JSValue JS_GetGlobalObject(
    ffi.Pointer<JSContext> ctx,
  ) {
    return _JS_GetGlobalObject(
      ctx,
    );
  }

  late final _JS_GetGlobalObjectPtr =
      _lookup<ffi.NativeFunction<JSValue Function(ffi.Pointer<JSContext>)>>(
          'JS_GetGlobalObject');
  late final _JS_GetGlobalObject = _JS_GetGlobalObjectPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>)>();

  int JS_IsInstanceOf(
    ffi.Pointer<JSContext> ctx,
    JSValue val,
    JSValue obj,
  ) {
    return _JS_IsInstanceOf(
      ctx,
      val,
      obj,
    );
  }

  late final _JS_IsInstanceOfPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_IsInstanceOf');
  late final _JS_IsInstanceOf = _JS_IsInstanceOfPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  int JS_DefineProperty(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int prop,
    JSValue val,
    JSValue getter,
    JSValue setter,
    int flags,
  ) {
    return _JS_DefineProperty(
      ctx,
      this_obj,
      prop,
      val,
      getter,
      setter,
      flags,
    );
  }

  late final _JS_DefinePropertyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, JSAtom, JSValue,
              JSValue, JSValue, ffi.Int)>>('JS_DefineProperty');
  late final _JS_DefineProperty = _JS_DefinePropertyPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int, JSValue, JSValue,
          JSValue, int)>();

  int JS_DefinePropertyValue(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int prop,
    JSValue val,
    int flags,
  ) {
    return _JS_DefinePropertyValue(
      ctx,
      this_obj,
      prop,
      val,
      flags,
    );
  }

  late final _JS_DefinePropertyValuePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, JSAtom, JSValue,
              ffi.Int)>>('JS_DefinePropertyValue');
  late final _JS_DefinePropertyValue = _JS_DefinePropertyValuePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue, int, JSValue, int)>();

  int JS_DefinePropertyValueUint32(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int idx,
    JSValue val,
    int flags,
  ) {
    return _JS_DefinePropertyValueUint32(
      ctx,
      this_obj,
      idx,
      val,
      flags,
    );
  }

  late final _JS_DefinePropertyValueUint32Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, ffi.Uint32, JSValue,
              ffi.Int)>>('JS_DefinePropertyValueUint32');
  late final _JS_DefinePropertyValueUint32 =
      _JS_DefinePropertyValueUint32Ptr.asFunction<
          int Function(ffi.Pointer<JSContext>, JSValue, int, JSValue, int)>();

  int JS_DefinePropertyValueStr(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    ffi.Pointer<ffi.Char> prop,
    JSValue val,
    int flags,
  ) {
    return _JS_DefinePropertyValueStr(
      ctx,
      this_obj,
      prop,
      val,
      flags,
    );
  }

  late final _JS_DefinePropertyValueStrPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>,
              JSValue,
              ffi.Pointer<ffi.Char>,
              JSValue,
              ffi.Int)>>('JS_DefinePropertyValueStr');
  late final _JS_DefinePropertyValueStr =
      _JS_DefinePropertyValueStrPtr.asFunction<
          int Function(ffi.Pointer<JSContext>, JSValue, ffi.Pointer<ffi.Char>,
              JSValue, int)>();

  int JS_DefinePropertyGetSet(
    ffi.Pointer<JSContext> ctx,
    JSValue this_obj,
    int prop,
    JSValue getter,
    JSValue setter,
    int flags,
  ) {
    return _JS_DefinePropertyGetSet(
      ctx,
      this_obj,
      prop,
      getter,
      setter,
      flags,
    );
  }

  late final _JS_DefinePropertyGetSetPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, JSValue, JSAtom, JSValue,
              JSValue, ffi.Int)>>('JS_DefinePropertyGetSet');
  late final _JS_DefinePropertyGetSet = _JS_DefinePropertyGetSetPtr.asFunction<
      int Function(
          ffi.Pointer<JSContext>, JSValue, int, JSValue, JSValue, int)>();

  void JS_SetOpaque(
    JSValue obj,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetOpaque(
      obj,
      opaque,
    );
  }

  late final _JS_SetOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(JSValue, ffi.Pointer<ffi.Void>)>>('JS_SetOpaque');
  late final _JS_SetOpaque = _JS_SetOpaquePtr.asFunction<
      void Function(JSValue, ffi.Pointer<ffi.Void>)>();

  ffi.Pointer<ffi.Void> JS_GetOpaque(
    JSValue obj,
    int class_id,
  ) {
    return _JS_GetOpaque(
      obj,
      class_id,
    );
  }

  late final _JS_GetOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(JSValue, JSClassID)>>('JS_GetOpaque');
  late final _JS_GetOpaque = _JS_GetOpaquePtr.asFunction<
      ffi.Pointer<ffi.Void> Function(JSValue, int)>();

  ffi.Pointer<ffi.Void> JS_GetOpaque2(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    int class_id,
  ) {
    return _JS_GetOpaque2(
      ctx,
      obj,
      class_id,
    );
  }

  late final _JS_GetOpaque2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSContext>, JSValue, JSClassID)>>('JS_GetOpaque2');
  late final _JS_GetOpaque2 = _JS_GetOpaque2Ptr.asFunction<
      ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSContext>, JSValue, int)>();

  ffi.Pointer<ffi.Void> JS_GetAnyOpaque(
    JSValue obj,
    ffi.Pointer<JSClassID> class_id,
  ) {
    return _JS_GetAnyOpaque(
      obj,
      class_id,
    );
  }

  late final _JS_GetAnyOpaquePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              JSValue, ffi.Pointer<JSClassID>)>>('JS_GetAnyOpaque');
  late final _JS_GetAnyOpaque = _JS_GetAnyOpaquePtr.asFunction<
      ffi.Pointer<ffi.Void> Function(JSValue, ffi.Pointer<JSClassID>)>();

  /// 'buf' must be zero terminated i.e. buf[buf_len] = '\0'.
  JSValue JS_ParseJSON(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> buf,
    int buf_len,
    ffi.Pointer<ffi.Char> filename,
  ) {
    return _JS_ParseJSON(
      ctx,
      buf,
      buf_len,
      filename,
    );
  }

  late final _JS_ParseJSONPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Size, ffi.Pointer<ffi.Char>)>>('JS_ParseJSON');
  late final _JS_ParseJSON = _JS_ParseJSONPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int,
          ffi.Pointer<ffi.Char>)>();

  JSValue JS_ParseJSON2(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> buf,
    int buf_len,
    ffi.Pointer<ffi.Char> filename,
    int flags,
  ) {
    return _JS_ParseJSON2(
      ctx,
      buf,
      buf_len,
      filename,
      flags,
    );
  }

  late final _JS_ParseJSON2Ptr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Size, ffi.Pointer<ffi.Char>, ffi.Int)>>('JS_ParseJSON2');
  late final _JS_ParseJSON2 = _JS_ParseJSON2Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>, int,
          ffi.Pointer<ffi.Char>, int)>();

  JSValue JS_JSONStringify(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    JSValue replacer,
    JSValue space0,
  ) {
    return _JS_JSONStringify(
      ctx,
      obj,
      replacer,
      space0,
    );
  }

  late final _JS_JSONStringifyPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue,
              JSValue)>>('JS_JSONStringify');
  late final _JS_JSONStringify = _JS_JSONStringifyPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, JSValue, JSValue)>();

  JSValue JS_NewArrayBuffer(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Uint8> buf,
    int len,
    ffi.Pointer<JSFreeArrayBufferDataFunc> free_func,
    ffi.Pointer<ffi.Void> opaque,
    int is_shared,
  ) {
    return _JS_NewArrayBuffer(
      ctx,
      buf,
      len,
      free_func,
      opaque,
      is_shared,
    );
  }

  late final _JS_NewArrayBufferPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Uint8>,
              ffi.Size,
              ffi.Pointer<JSFreeArrayBufferDataFunc>,
              ffi.Pointer<ffi.Void>,
              ffi.Int)>>('JS_NewArrayBuffer');
  late final _JS_NewArrayBuffer = _JS_NewArrayBufferPtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<JSFreeArrayBufferDataFunc>,
          ffi.Pointer<ffi.Void>,
          int)>();

  JSValue JS_NewArrayBufferCopy(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Uint8> buf,
    int len,
  ) {
    return _JS_NewArrayBufferCopy(
      ctx,
      buf,
      len,
    );
  }

  late final _JS_NewArrayBufferCopyPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint8>,
              ffi.Size)>>('JS_NewArrayBufferCopy');
  late final _JS_NewArrayBufferCopy = _JS_NewArrayBufferCopyPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint8>, int)>();

  void JS_DetachArrayBuffer(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_DetachArrayBuffer(
      ctx,
      obj,
    );
  }

  late final _JS_DetachArrayBufferPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_DetachArrayBuffer');
  late final _JS_DetachArrayBuffer = _JS_DetachArrayBufferPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, JSValue)>();

  ffi.Pointer<ffi.Uint8> JS_GetArrayBuffer(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Size> psize,
    JSValue obj,
  ) {
    return _JS_GetArrayBuffer(
      ctx,
      psize,
      obj,
    );
  }

  late final _JS_GetArrayBufferPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Size>, JSValue)>>('JS_GetArrayBuffer');
  late final _JS_GetArrayBuffer = _JS_GetArrayBufferPtr.asFunction<
      ffi.Pointer<ffi.Uint8> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Size>, JSValue)>();

  JSValue JS_NewTypedArray(
    ffi.Pointer<JSContext> ctx,
    int argc,
    ffi.Pointer<JSValue> argv,
    JSTypedArrayEnum array_type,
  ) {
    return _JS_NewTypedArray(
      ctx,
      argc,
      argv,
      array_type.value,
    );
  }

  late final _JS_NewTypedArrayPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Int,
              ffi.Pointer<JSValue>, ffi.UnsignedInt)>>('JS_NewTypedArray');
  late final _JS_NewTypedArray = _JS_NewTypedArrayPtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>, int, ffi.Pointer<JSValue>, int)>();

  JSValue JS_GetTypedArrayBuffer(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    ffi.Pointer<ffi.Size> pbyte_offset,
    ffi.Pointer<ffi.Size> pbyte_length,
    ffi.Pointer<ffi.Size> pbytes_per_element,
  ) {
    return _JS_GetTypedArrayBuffer(
      ctx,
      obj,
      pbyte_offset,
      pbyte_length,
      pbytes_per_element,
    );
  }

  late final _JS_GetTypedArrayBufferPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>,
              JSValue,
              ffi.Pointer<ffi.Size>,
              ffi.Pointer<ffi.Size>,
              ffi.Pointer<ffi.Size>)>>('JS_GetTypedArrayBuffer');
  late final _JS_GetTypedArrayBuffer = _JS_GetTypedArrayBufferPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue, ffi.Pointer<ffi.Size>,
          ffi.Pointer<ffi.Size>, ffi.Pointer<ffi.Size>)>();

  void JS_SetSharedArrayBufferFunctions(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<JSSharedArrayBufferFunctions> sf,
  ) {
    return _JS_SetSharedArrayBufferFunctions(
      rt,
      sf,
    );
  }

  late final _JS_SetSharedArrayBufferFunctionsPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Pointer<JSRuntime>,
                  ffi.Pointer<JSSharedArrayBufferFunctions>)>>(
      'JS_SetSharedArrayBufferFunctions');
  late final _JS_SetSharedArrayBufferFunctions =
      _JS_SetSharedArrayBufferFunctionsPtr.asFunction<
          void Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSSharedArrayBufferFunctions>)>();

  JSValue JS_NewPromiseCapability(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSValue> resolving_funcs,
  ) {
    return _JS_NewPromiseCapability(
      ctx,
      resolving_funcs,
    );
  }

  late final _JS_NewPromiseCapabilityPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<JSValue>)>>('JS_NewPromiseCapability');
  late final _JS_NewPromiseCapability = _JS_NewPromiseCapabilityPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<JSValue>)>();

  JSPromiseStateEnum JS_PromiseState(
    ffi.Pointer<JSContext> ctx,
    JSValue promise,
  ) {
    return JSPromiseStateEnum.fromValue(_JS_PromiseState(
      ctx,
      promise,
    ));
  }

  late final _JS_PromiseStatePtr = _lookup<
      ffi.NativeFunction<
          ffi.UnsignedInt Function(
              ffi.Pointer<JSContext>, JSValue)>>('JS_PromiseState');
  late final _JS_PromiseState = _JS_PromiseStatePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  JSValue JS_PromiseResult(
    ffi.Pointer<JSContext> ctx,
    JSValue promise,
  ) {
    return _JS_PromiseResult(
      ctx,
      promise,
    );
  }

  late final _JS_PromiseResultPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_PromiseResult');
  late final _JS_PromiseResult = _JS_PromiseResultPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  void JS_SetHostPromiseRejectionTracker(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<JSHostPromiseRejectionTracker> cb,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetHostPromiseRejectionTracker(
      rt,
      cb,
      opaque,
    );
  }

  late final _JS_SetHostPromiseRejectionTrackerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSHostPromiseRejectionTracker>,
              ffi.Pointer<ffi.Void>)>>('JS_SetHostPromiseRejectionTracker');
  late final _JS_SetHostPromiseRejectionTracker =
      _JS_SetHostPromiseRejectionTrackerPtr.asFunction<
          void Function(
              ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSHostPromiseRejectionTracker>,
              ffi.Pointer<ffi.Void>)>();

  void JS_SetInterruptHandler(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<JSInterruptHandler> cb,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetInterruptHandler(
      rt,
      cb,
      opaque,
    );
  }

  late final _JS_SetInterruptHandlerPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSInterruptHandler>,
              ffi.Pointer<ffi.Void>)>>('JS_SetInterruptHandler');
  late final _JS_SetInterruptHandler = _JS_SetInterruptHandlerPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<JSInterruptHandler>,
          ffi.Pointer<ffi.Void>)>();

  /// if can_block is TRUE, Atomics.wait() can be used
  void JS_SetCanBlock(
    ffi.Pointer<JSRuntime> rt,
    int can_block,
  ) {
    return _JS_SetCanBlock(
      rt,
      can_block,
    );
  }

  late final _JS_SetCanBlockPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, ffi.Int)>>(
      'JS_SetCanBlock');
  late final _JS_SetCanBlock = _JS_SetCanBlockPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  void JS_SetStripInfo(
    ffi.Pointer<JSRuntime> rt,
    int flags,
  ) {
    return _JS_SetStripInfo(
      rt,
      flags,
    );
  }

  late final _JS_SetStripInfoPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime>, ffi.Int)>>(
      'JS_SetStripInfo');
  late final _JS_SetStripInfo = _JS_SetStripInfoPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, int)>();

  int JS_GetStripInfo(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_GetStripInfo(
      rt,
    );
  }

  late final _JS_GetStripInfoPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<JSRuntime>)>>(
          'JS_GetStripInfo');
  late final _JS_GetStripInfo =
      _JS_GetStripInfoPtr.asFunction<int Function(ffi.Pointer<JSRuntime>)>();

  /// set the [IsHTMLDDA] internal slot
  void JS_SetIsHTMLDDA(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_SetIsHTMLDDA(
      ctx,
      obj,
    );
  }

  late final _JS_SetIsHTMLDDAPtr = _lookup<
          ffi
          .NativeFunction<ffi.Void Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_SetIsHTMLDDA');
  late final _JS_SetIsHTMLDDA = _JS_SetIsHTMLDDAPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, JSValue)>();

  /// module_normalize = NULL is allowed and invokes the default module
  /// filename normalizer
  void JS_SetModuleLoaderFunc(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<JSModuleNormalizeFunc> module_normalize,
    ffi.Pointer<JSModuleLoaderFunc> module_loader,
    ffi.Pointer<ffi.Void> opaque,
  ) {
    return _JS_SetModuleLoaderFunc(
      rt,
      module_normalize,
      module_loader,
      opaque,
    );
  }

  late final _JS_SetModuleLoaderFuncPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSRuntime>,
              ffi.Pointer<JSModuleNormalizeFunc>,
              ffi.Pointer<JSModuleLoaderFunc>,
              ffi.Pointer<ffi.Void>)>>('JS_SetModuleLoaderFunc');
  late final _JS_SetModuleLoaderFunc = _JS_SetModuleLoaderFuncPtr.asFunction<
      void Function(ffi.Pointer<JSRuntime>, ffi.Pointer<JSModuleNormalizeFunc>,
          ffi.Pointer<JSModuleLoaderFunc>, ffi.Pointer<ffi.Void>)>();

  /// return the import.meta object of a module
  JSValue JS_GetImportMeta(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
  ) {
    return _JS_GetImportMeta(
      ctx,
      m,
    );
  }

  late final _JS_GetImportMetaPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<JSModuleDef>)>>('JS_GetImportMeta');
  late final _JS_GetImportMeta = _JS_GetImportMetaPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>)>();

  int JS_GetModuleName(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
  ) {
    return _JS_GetModuleName(
      ctx,
      m,
    );
  }

  late final _JS_GetModuleNamePtr = _lookup<
      ffi.NativeFunction<
          JSAtom Function(ffi.Pointer<JSContext>,
              ffi.Pointer<JSModuleDef>)>>('JS_GetModuleName');
  late final _JS_GetModuleName = _JS_GetModuleNamePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>)>();

  JSValue JS_GetModuleNamespace(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
  ) {
    return _JS_GetModuleNamespace(
      ctx,
      m,
    );
  }

  late final _JS_GetModuleNamespacePtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>,
              ffi.Pointer<JSModuleDef>)>>('JS_GetModuleNamespace');
  late final _JS_GetModuleNamespace = _JS_GetModuleNamespacePtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>)>();

  int JS_EnqueueJob(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSJobFunc> job_func,
    int argc,
    ffi.Pointer<JSValue> argv,
  ) {
    return _JS_EnqueueJob(
      ctx,
      job_func,
      argc,
      argv,
    );
  }

  late final _JS_EnqueueJobPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSJobFunc>,
              ffi.Int, ffi.Pointer<JSValue>)>>('JS_EnqueueJob');
  late final _JS_EnqueueJob = _JS_EnqueueJobPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSJobFunc>, int,
          ffi.Pointer<JSValue>)>();

  int JS_IsJobPending(
    ffi.Pointer<JSRuntime> rt,
  ) {
    return _JS_IsJobPending(
      rt,
    );
  }

  late final _JS_IsJobPendingPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Pointer<JSRuntime>)>>(
          'JS_IsJobPending');
  late final _JS_IsJobPending =
      _JS_IsJobPendingPtr.asFunction<int Function(ffi.Pointer<JSRuntime>)>();

  int JS_ExecutePendingJob(
    ffi.Pointer<JSRuntime> rt,
    ffi.Pointer<ffi.Pointer<JSContext>> pctx,
  ) {
    return _JS_ExecutePendingJob(
      rt,
      pctx,
    );
  }

  late final _JS_ExecutePendingJobPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSRuntime>,
              ffi.Pointer<ffi.Pointer<JSContext>>)>>('JS_ExecutePendingJob');
  late final _JS_ExecutePendingJob = _JS_ExecutePendingJobPtr.asFunction<
      int Function(
          ffi.Pointer<JSRuntime>, ffi.Pointer<ffi.Pointer<JSContext>>)>();

  ffi.Pointer<ffi.Uint8> JS_WriteObject(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Size> psize,
    JSValue obj,
    int flags,
  ) {
    return _JS_WriteObject(
      ctx,
      psize,
      obj,
      flags,
    );
  }

  late final _JS_WriteObjectPtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Size>, JSValue, ffi.Int)>>('JS_WriteObject');
  late final _JS_WriteObject = _JS_WriteObjectPtr.asFunction<
      ffi.Pointer<ffi.Uint8> Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Size>, JSValue, int)>();

  ffi.Pointer<ffi.Uint8> JS_WriteObject2(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Size> psize,
    JSValue obj,
    int flags,
    ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Uint8>>> psab_tab,
    ffi.Pointer<ffi.Size> psab_tab_len,
  ) {
    return _JS_WriteObject2(
      ctx,
      psize,
      obj,
      flags,
      psab_tab,
      psab_tab_len,
    );
  }

  late final _JS_WriteObject2Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Uint8> Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Size>,
              JSValue,
              ffi.Int,
              ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Uint8>>>,
              ffi.Pointer<ffi.Size>)>>('JS_WriteObject2');
  late final _JS_WriteObject2 = _JS_WriteObject2Ptr.asFunction<
      ffi.Pointer<ffi.Uint8> Function(
          ffi.Pointer<JSContext>,
          ffi.Pointer<ffi.Size>,
          JSValue,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Pointer<ffi.Uint8>>>,
          ffi.Pointer<ffi.Size>)>();

  JSValue JS_ReadObject(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Uint8> buf,
    int buf_len,
    int flags,
  ) {
    return _JS_ReadObject(
      ctx,
      buf,
      buf_len,
      flags,
    );
  }

  late final _JS_ReadObjectPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint8>,
              ffi.Size, ffi.Int)>>('JS_ReadObject');
  late final _JS_ReadObject = _JS_ReadObjectPtr.asFunction<
      JSValue Function(
          ffi.Pointer<JSContext>, ffi.Pointer<ffi.Uint8>, int, int)>();

  /// instantiate and evaluate a bytecode function. Only used when
  /// reading a script or module with JS_ReadObject()
  JSValue JS_EvalFunction(
    ffi.Pointer<JSContext> ctx,
    JSValue fun_obj,
  ) {
    return _JS_EvalFunction(
      ctx,
      fun_obj,
    );
  }

  late final _JS_EvalFunctionPtr = _lookup<
          ffi
          .NativeFunction<JSValue Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_EvalFunction');
  late final _JS_EvalFunction = _JS_EvalFunctionPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, JSValue)>();

  /// load the dependencies of the module 'obj'. Useful when JS_ReadObject()
  /// returns a module.
  int JS_ResolveModule(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
  ) {
    return _JS_ResolveModule(
      ctx,
      obj,
    );
  }

  late final _JS_ResolveModulePtr = _lookup<
          ffi
          .NativeFunction<ffi.Int Function(ffi.Pointer<JSContext>, JSValue)>>(
      'JS_ResolveModule');
  late final _JS_ResolveModule = _JS_ResolveModulePtr.asFunction<
      int Function(ffi.Pointer<JSContext>, JSValue)>();

  /// only exported for os.Worker()
  int JS_GetScriptOrModuleName(
    ffi.Pointer<JSContext> ctx,
    int n_stack_levels,
  ) {
    return _JS_GetScriptOrModuleName(
      ctx,
      n_stack_levels,
    );
  }

  late final _JS_GetScriptOrModuleNamePtr = _lookup<
          ffi.NativeFunction<JSAtom Function(ffi.Pointer<JSContext>, ffi.Int)>>(
      'JS_GetScriptOrModuleName');
  late final _JS_GetScriptOrModuleName = _JS_GetScriptOrModuleNamePtr
      .asFunction<int Function(ffi.Pointer<JSContext>, int)>();

  /// only exported for os.Worker()
  JSValue JS_LoadModule(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> basename,
    ffi.Pointer<ffi.Char> filename,
  ) {
    return _JS_LoadModule(
      ctx,
      basename,
      filename,
    );
  }

  late final _JS_LoadModulePtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
              ffi.Pointer<ffi.Char>)>>('JS_LoadModule');
  late final _JS_LoadModule = _JS_LoadModulePtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>)>();

  JSValue JS_NewCFunction2(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSCFunction> func,
    ffi.Pointer<ffi.Char> name,
    int length,
    JSCFunctionEnum cproto,
    int magic,
  ) {
    return _JS_NewCFunction2(
      ctx,
      func,
      name,
      length,
      cproto.value,
      magic,
    );
  }

  late final _JS_NewCFunction2Ptr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<JSCFunction>,
              ffi.Pointer<ffi.Char>,
              ffi.Int,
              ffi.UnsignedInt,
              ffi.Int)>>('JS_NewCFunction2');
  late final _JS_NewCFunction2 = _JS_NewCFunction2Ptr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<JSCFunction>,
          ffi.Pointer<ffi.Char>, int, int, int)>();

  JSValue JS_NewCFunctionData(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSCFunctionData> func,
    int length,
    int magic,
    int data_len,
    ffi.Pointer<JSValue> data,
  ) {
    return _JS_NewCFunctionData(
      ctx,
      func,
      length,
      magic,
      data_len,
      data,
    );
  }

  late final _JS_NewCFunctionDataPtr = _lookup<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<JSCFunctionData>,
              ffi.Int,
              ffi.Int,
              ffi.Int,
              ffi.Pointer<JSValue>)>>('JS_NewCFunctionData');
  late final _JS_NewCFunctionData = _JS_NewCFunctionDataPtr.asFunction<
      JSValue Function(ffi.Pointer<JSContext>, ffi.Pointer<JSCFunctionData>,
          int, int, int, ffi.Pointer<JSValue>)>();

  void JS_SetConstructor(
    ffi.Pointer<JSContext> ctx,
    JSValue func_obj,
    JSValue proto,
  ) {
    return _JS_SetConstructor(
      ctx,
      func_obj,
      proto,
    );
  }

  late final _JS_SetConstructorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSContext>, JSValue, JSValue)>>('JS_SetConstructor');
  late final _JS_SetConstructor = _JS_SetConstructorPtr.asFunction<
      void Function(ffi.Pointer<JSContext>, JSValue, JSValue)>();

  void JS_SetPropertyFunctionList(
    ffi.Pointer<JSContext> ctx,
    JSValue obj,
    ffi.Pointer<JSCFunctionListEntry> tab,
    int len,
  ) {
    return _JS_SetPropertyFunctionList(
      ctx,
      obj,
      tab,
      len,
    );
  }

  late final _JS_SetPropertyFunctionListPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Pointer<JSContext>,
              JSValue,
              ffi.Pointer<JSCFunctionListEntry>,
              ffi.Int)>>('JS_SetPropertyFunctionList');
  late final _JS_SetPropertyFunctionList =
      _JS_SetPropertyFunctionListPtr.asFunction<
          void Function(ffi.Pointer<JSContext>, JSValue,
              ffi.Pointer<JSCFunctionListEntry>, int)>();

  ffi.Pointer<JSModuleDef> JS_NewCModule(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<ffi.Char> name_str,
    ffi.Pointer<JSModuleInitFunc> func,
  ) {
    return _JS_NewCModule(
      ctx,
      name_str,
      func,
    );
  }

  late final _JS_NewCModulePtr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<JSModuleDef> Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<ffi.Char>,
              ffi.Pointer<JSModuleInitFunc>)>>('JS_NewCModule');
  late final _JS_NewCModule = _JS_NewCModulePtr.asFunction<
      ffi.Pointer<JSModuleDef> Function(ffi.Pointer<JSContext>,
          ffi.Pointer<ffi.Char>, ffi.Pointer<JSModuleInitFunc>)>();

  /// can only be called before the module is instantiated
  int JS_AddModuleExport(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
    ffi.Pointer<ffi.Char> name_str,
  ) {
    return _JS_AddModuleExport(
      ctx,
      m,
      name_str,
    );
  }

  late final _JS_AddModuleExportPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
              ffi.Pointer<ffi.Char>)>>('JS_AddModuleExport');
  late final _JS_AddModuleExport = _JS_AddModuleExportPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
          ffi.Pointer<ffi.Char>)>();

  int JS_AddModuleExportList(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
    ffi.Pointer<JSCFunctionListEntry> tab,
    int len,
  ) {
    return _JS_AddModuleExportList(
      ctx,
      m,
      tab,
      len,
    );
  }

  late final _JS_AddModuleExportListPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<JSModuleDef>,
              ffi.Pointer<JSCFunctionListEntry>,
              ffi.Int)>>('JS_AddModuleExportList');
  late final _JS_AddModuleExportList = _JS_AddModuleExportListPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
          ffi.Pointer<JSCFunctionListEntry>, int)>();

  /// can only be called after the module is instantiated
  int JS_SetModuleExport(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
    ffi.Pointer<ffi.Char> export_name,
    JSValue val,
  ) {
    return _JS_SetModuleExport(
      ctx,
      m,
      export_name,
      val,
    );
  }

  late final _JS_SetModuleExportPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
              ffi.Pointer<ffi.Char>, JSValue)>>('JS_SetModuleExport');
  late final _JS_SetModuleExport = _JS_SetModuleExportPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
          ffi.Pointer<ffi.Char>, JSValue)>();

  int JS_SetModuleExportList(
    ffi.Pointer<JSContext> ctx,
    ffi.Pointer<JSModuleDef> m,
    ffi.Pointer<JSCFunctionListEntry> tab,
    int len,
  ) {
    return _JS_SetModuleExportList(
      ctx,
      m,
      tab,
      len,
    );
  }

  late final _JS_SetModuleExportListPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext>,
              ffi.Pointer<JSModuleDef>,
              ffi.Pointer<JSCFunctionListEntry>,
              ffi.Int)>>('JS_SetModuleExportList');
  late final _JS_SetModuleExportList = _JS_SetModuleExportListPtr.asFunction<
      int Function(ffi.Pointer<JSContext>, ffi.Pointer<JSModuleDef>,
          ffi.Pointer<JSCFunctionListEntry>, int)>();
}

final class JSRuntime extends ffi.Opaque {}

final class JSContext extends ffi.Opaque {}

final class JSClass extends ffi.Opaque {}

final class JSRefCountHeader extends ffi.Struct {
  @ffi.Int()
  external int ref_count;
}

final class JSValueUnion extends ffi.Union {
  @ffi.Int32()
  external int int32;

  @ffi.Double()
  external double float64;

  external ffi.Pointer<ffi.Void> ptr;

  @ffi.Int64()
  external int short_big_int;
}

final class JSValue extends ffi.Struct {
  external JSValueUnion u;

  @ffi.Int64()
  external int tag;
}

final class JSMallocState extends ffi.Struct {
  @ffi.Size()
  external int malloc_count;

  @ffi.Size()
  external int malloc_size;

  @ffi.Size()
  external int malloc_limit;

  /// user opaque
  external ffi.Pointer<ffi.Void> opaque;
}

final class JSMallocFunctions extends ffi.Struct {
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<JSMallocState> s, ffi.Size size)>> js_malloc;

  external ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<JSMallocState> s, ffi.Pointer<ffi.Void> ptr)>>
      js_free;

  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(ffi.Pointer<JSMallocState> s,
              ffi.Pointer<ffi.Void> ptr, ffi.Size size)>> js_realloc;

  external ffi
      .Pointer<ffi.NativeFunction<ffi.Size Function(ffi.Pointer<ffi.Void> ptr)>>
      js_malloc_usable_size;
}

final class JSGCObjectHeader extends ffi.Opaque {}

typedef JS_MarkFunc = ffi.NativeFunction<
    ffi.Void Function(
        ffi.Pointer<JSRuntime> rt, ffi.Pointer<JSGCObjectHeader> gp)>;
typedef JSClassID = ffi.Uint32;
typedef DartJSClassID = int;

final class JSMemoryUsage extends ffi.Struct {
  @ffi.Int64()
  external int malloc_size;

  @ffi.Int64()
  external int malloc_limit;

  @ffi.Int64()
  external int memory_used_size;

  @ffi.Int64()
  external int malloc_count;

  @ffi.Int64()
  external int memory_used_count;

  @ffi.Int64()
  external int atom_count;

  @ffi.Int64()
  external int atom_size;

  @ffi.Int64()
  external int str_count;

  @ffi.Int64()
  external int str_size;

  @ffi.Int64()
  external int obj_count;

  @ffi.Int64()
  external int obj_size;

  @ffi.Int64()
  external int prop_count;

  @ffi.Int64()
  external int prop_size;

  @ffi.Int64()
  external int shape_count;

  @ffi.Int64()
  external int shape_size;

  @ffi.Int64()
  external int js_func_count;

  @ffi.Int64()
  external int js_func_size;

  @ffi.Int64()
  external int js_func_code_size;

  @ffi.Int64()
  external int js_func_pc2line_count;

  @ffi.Int64()
  external int js_func_pc2line_size;

  @ffi.Int64()
  external int c_func_count;

  @ffi.Int64()
  external int array_count;

  @ffi.Int64()
  external int fast_array_count;

  @ffi.Int64()
  external int fast_array_elements;

  @ffi.Int64()
  external int binary_object_count;

  @ffi.Int64()
  external int binary_object_size;
}

typedef FILE = _IO_FILE;

final class _IO_FILE extends ffi.Struct {
  @ffi.Int()
  external int _flags;

  external ffi.Pointer<ffi.Char> _IO_read_ptr;

  external ffi.Pointer<ffi.Char> _IO_read_end;

  external ffi.Pointer<ffi.Char> _IO_read_base;

  external ffi.Pointer<ffi.Char> _IO_write_base;

  external ffi.Pointer<ffi.Char> _IO_write_ptr;

  external ffi.Pointer<ffi.Char> _IO_write_end;

  external ffi.Pointer<ffi.Char> _IO_buf_base;

  external ffi.Pointer<ffi.Char> _IO_buf_end;

  external ffi.Pointer<ffi.Char> _IO_save_base;

  external ffi.Pointer<ffi.Char> _IO_backup_base;

  external ffi.Pointer<ffi.Char> _IO_save_end;

  external ffi.Pointer<_IO_marker> _markers;

  external ffi.Pointer<_IO_FILE> _chain;

  @ffi.Int()
  external int _fileno;

  @ffi.Int()
  external int _flags2;

  @__off_t()
  external int _old_offset;

  @ffi.UnsignedShort()
  external int _cur_column;

  @ffi.SignedChar()
  external int _vtable_offset;

  @ffi.Array.multi([1])
  external ffi.Array<ffi.Char> _shortbuf;

  external ffi.Pointer<_IO_lock_t> _lock;

  @__off64_t()
  external int _offset;

  external ffi.Pointer<_IO_codecvt> _codecvt;

  external ffi.Pointer<_IO_wide_data> _wide_data;

  external ffi.Pointer<_IO_FILE> _freeres_list;

  external ffi.Pointer<ffi.Void> _freeres_buf;

  @ffi.Size()
  external int __pad5;

  @ffi.Int()
  external int _mode;

  @ffi.Array.multi([20])
  external ffi.Array<ffi.Char> _unused2;
}

final class _IO_marker extends ffi.Opaque {}

typedef __off_t = ffi.Long;
typedef Dart__off_t = int;
typedef _IO_lock_t = ffi.Void;
typedef Dart_IO_lock_t = void;
typedef __off64_t = ffi.Long;
typedef Dart__off64_t = int;

final class _IO_codecvt extends ffi.Opaque {}

final class _IO_wide_data extends ffi.Opaque {}

typedef JSAtom = ffi.Uint32;
typedef DartJSAtom = int;

/// object class support
final class JSPropertyEnum extends ffi.Struct {
  @ffi.Int()
  external int is_enumerable;

  @JSAtom()
  external int atom;
}

final class JSPropertyDescriptor extends ffi.Struct {
  @ffi.Int()
  external int flags;

  external JSValue value;

  external JSValue getter;

  external JSValue setter;
}

final class JSClassExoticMethods extends ffi.Struct {
  /// Return -1 if exception (can only happen in case of Proxy object),
  /// FALSE if the property does not exists, TRUE if it exists. If 1 is
  /// returned, the property descriptor 'desc' is filled if != NULL.
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext> ctx,
              ffi.Pointer<JSPropertyDescriptor> desc,
              JSValue obj,
              JSAtom prop)>> get_own_property;

  /// '*ptab' should hold the '*plen' property keys. Return 0 if OK,
  /// -1 if exception. The 'is_enumerable' field is ignored.
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext> ctx,
              ffi.Pointer<ffi.Pointer<JSPropertyEnum>> ptab,
              ffi.Pointer<ffi.Uint32> plen,
              JSValue obj)>> get_own_property_names;

  /// return < 0 if exception, or TRUE/FALSE
  external ffi.Pointer<
          ffi.NativeFunction<
              ffi.Int Function(
                  ffi.Pointer<JSContext> ctx, JSValue obj, JSAtom prop)>>
      delete_property;

  /// return < 0 if exception or TRUE/FALSE
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<JSContext> ctx,
              JSValue this_obj,
              JSAtom prop,
              JSValue val,
              JSValue getter,
              JSValue setter,
              ffi.Int flags)>> define_own_property;

  /// The following methods can be emulated with the previous ones,
  /// so they are usually not needed */
  /// /* return < 0 if exception or TRUE/FALSE
  external ffi.Pointer<
          ffi.NativeFunction<
              ffi.Int Function(
                  ffi.Pointer<JSContext> ctx, JSValue obj, JSAtom atom)>>
      has_property;

  external ffi.Pointer<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext> ctx, JSValue obj, JSAtom atom,
              JSValue receiver)>> get_property;

  /// return < 0 if exception or TRUE/FALSE
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Int Function(ffi.Pointer<JSContext> ctx, JSValue obj, JSAtom atom,
              JSValue value, JSValue receiver, ffi.Int flags)>> set_property;
}

final class JSClassDef extends ffi.Struct {
  external ffi.Pointer<ffi.Char> class_name;

  external ffi.Pointer<JSClassFinalizer> finalizer;

  external ffi.Pointer<JSClassGCMark> gc_mark;

  /// if call != NULL, the object is a function. If (flags &
  /// JS_CALL_FLAG_CONSTRUCTOR) != 0, the function is called as a
  /// constructor. In this case, 'this_val' is new.target. A
  /// constructor call only happens if the object constructor bit is
  /// set (see JS_SetConstructorBit()).
  external ffi.Pointer<JSClassCall> call;

  /// XXX: suppress this indirection ? It is here only to save memory
  /// because only a few classes need these methods
  external ffi.Pointer<JSClassExoticMethods> exotic;
}

typedef JSClassFinalizer = ffi
    .NativeFunction<ffi.Void Function(ffi.Pointer<JSRuntime> rt, JSValue val)>;
typedef JSClassGCMark = ffi.NativeFunction<
    ffi.Void Function(ffi.Pointer<JSRuntime> rt, JSValue val,
        ffi.Pointer<JS_MarkFunc> mark_func)>;
typedef JSClassCall = ffi.NativeFunction<
    JSValue Function(
        ffi.Pointer<JSContext> ctx,
        JSValue func_obj,
        JSValue this_val,
        ffi.Int argc,
        ffi.Pointer<JSValue> argv,
        ffi.Int flags)>;
typedef JSFreeArrayBufferDataFunc = ffi.NativeFunction<
    ffi.Void Function(ffi.Pointer<JSRuntime> rt, ffi.Pointer<ffi.Void> opaque,
        ffi.Pointer<ffi.Void> ptr)>;

enum JSTypedArrayEnum {
  JS_TYPED_ARRAY_UINT8C(0),
  JS_TYPED_ARRAY_INT8(1),
  JS_TYPED_ARRAY_UINT8(2),
  JS_TYPED_ARRAY_INT16(3),
  JS_TYPED_ARRAY_UINT16(4),
  JS_TYPED_ARRAY_INT32(5),
  JS_TYPED_ARRAY_UINT32(6),
  JS_TYPED_ARRAY_BIG_INT64(7),
  JS_TYPED_ARRAY_BIG_UINT64(8),
  JS_TYPED_ARRAY_FLOAT32(9),
  JS_TYPED_ARRAY_FLOAT64(10);

  final int value;
  const JSTypedArrayEnum(this.value);

  static JSTypedArrayEnum fromValue(int value) => switch (value) {
        0 => JS_TYPED_ARRAY_UINT8C,
        1 => JS_TYPED_ARRAY_INT8,
        2 => JS_TYPED_ARRAY_UINT8,
        3 => JS_TYPED_ARRAY_INT16,
        4 => JS_TYPED_ARRAY_UINT16,
        5 => JS_TYPED_ARRAY_INT32,
        6 => JS_TYPED_ARRAY_UINT32,
        7 => JS_TYPED_ARRAY_BIG_INT64,
        8 => JS_TYPED_ARRAY_BIG_UINT64,
        9 => JS_TYPED_ARRAY_FLOAT32,
        10 => JS_TYPED_ARRAY_FLOAT64,
        _ => throw ArgumentError("Unknown value for JSTypedArrayEnum: $value"),
      };
}

final class JSSharedArrayBufferFunctions extends ffi.Struct {
  external ffi.Pointer<
      ffi.NativeFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<ffi.Void> opaque, ffi.Size size)>> sab_alloc;

  external ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<ffi.Void> opaque, ffi.Pointer<ffi.Void> ptr)>>
      sab_free;

  external ffi.Pointer<
          ffi.NativeFunction<
              ffi.Void Function(
                  ffi.Pointer<ffi.Void> opaque, ffi.Pointer<ffi.Void> ptr)>>
      sab_dup;

  external ffi.Pointer<ffi.Void> sab_opaque;
}

enum JSPromiseStateEnum {
  JS_PROMISE_PENDING(0),
  JS_PROMISE_FULFILLED(1),
  JS_PROMISE_REJECTED(2);

  final int value;
  const JSPromiseStateEnum(this.value);

  static JSPromiseStateEnum fromValue(int value) => switch (value) {
        0 => JS_PROMISE_PENDING,
        1 => JS_PROMISE_FULFILLED,
        2 => JS_PROMISE_REJECTED,
        _ =>
          throw ArgumentError("Unknown value for JSPromiseStateEnum: $value"),
      };
}

/// is_handled = TRUE means that the rejection is handled
typedef JSHostPromiseRejectionTracker = ffi.NativeFunction<
    ffi.Void Function(ffi.Pointer<JSContext> ctx, JSValue promise,
        JSValue reason, ffi.Int is_handled, ffi.Pointer<ffi.Void> opaque)>;

/// return != 0 if the JS code needs to be interrupted
typedef JSInterruptHandler = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<JSRuntime> rt, ffi.Pointer<ffi.Void> opaque)>;

final class JSModuleDef extends ffi.Opaque {}

/// return the module specifier (allocated with js_malloc()) or NULL if
/// exception
typedef JSModuleNormalizeFunc = ffi.NativeFunction<
    ffi.Pointer<ffi.Char> Function(
        ffi.Pointer<JSContext> ctx,
        ffi.Pointer<ffi.Char> module_base_name,
        ffi.Pointer<ffi.Char> module_name,
        ffi.Pointer<ffi.Void> opaque)>;
typedef JSModuleLoaderFunc = ffi.NativeFunction<
    ffi.Pointer<JSModuleDef> Function(ffi.Pointer<JSContext> ctx,
        ffi.Pointer<ffi.Char> module_name, ffi.Pointer<ffi.Void> opaque)>;

/// JS Job support
typedef JSJobFunc = ffi.NativeFunction<
    JSValue Function(
        ffi.Pointer<JSContext> ctx, ffi.Int argc, ffi.Pointer<JSValue> argv)>;

/// C function definition
enum JSCFunctionEnum {
  JS_CFUNC_generic(0),
  JS_CFUNC_generic_magic(1),
  JS_CFUNC_constructor(2),
  JS_CFUNC_constructor_magic(3),
  JS_CFUNC_constructor_or_func(4),
  JS_CFUNC_constructor_or_func_magic(5),
  JS_CFUNC_f_f(6),
  JS_CFUNC_f_f_f(7),
  JS_CFUNC_getter(8),
  JS_CFUNC_setter(9),
  JS_CFUNC_getter_magic(10),
  JS_CFUNC_setter_magic(11),
  JS_CFUNC_iterator_next(12);

  final int value;
  const JSCFunctionEnum(this.value);

  static JSCFunctionEnum fromValue(int value) => switch (value) {
        0 => JS_CFUNC_generic,
        1 => JS_CFUNC_generic_magic,
        2 => JS_CFUNC_constructor,
        3 => JS_CFUNC_constructor_magic,
        4 => JS_CFUNC_constructor_or_func,
        5 => JS_CFUNC_constructor_or_func_magic,
        6 => JS_CFUNC_f_f,
        7 => JS_CFUNC_f_f_f,
        8 => JS_CFUNC_getter,
        9 => JS_CFUNC_setter,
        10 => JS_CFUNC_getter_magic,
        11 => JS_CFUNC_setter_magic,
        12 => JS_CFUNC_iterator_next,
        _ => throw ArgumentError("Unknown value for JSCFunctionEnum: $value"),
      };
}

final class JSCFunctionType extends ffi.Union {
  external ffi.Pointer<JSCFunction> generic;

  external ffi.Pointer<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext> ctx,
              JSValue this_val,
              ffi.Int argc,
              ffi.Pointer<JSValue> argv,
              ffi.Int magic)>> generic_magic;

  external ffi.Pointer<JSCFunction> constructor;

  external ffi.Pointer<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext> ctx,
              JSValue new_target,
              ffi.Int argc,
              ffi.Pointer<JSValue> argv,
              ffi.Int magic)>> constructor_magic;

  external ffi.Pointer<JSCFunction> constructor_or_func;

  external ffi.Pointer<ffi.NativeFunction<ffi.Double Function(ffi.Double)>> f_f;

  external ffi
      .Pointer<ffi.NativeFunction<ffi.Double Function(ffi.Double, ffi.Double)>>
      f_f_f;

  external ffi.Pointer<
          ffi.NativeFunction<
              JSValue Function(ffi.Pointer<JSContext> ctx, JSValue this_val)>>
      getter;

  external ffi.Pointer<
          ffi.NativeFunction<
              JSValue Function(
                  ffi.Pointer<JSContext> ctx, JSValue this_val, JSValue val)>>
      setter;

  external ffi.Pointer<
          ffi.NativeFunction<
              JSValue Function(
                  ffi.Pointer<JSContext> ctx, JSValue this_val, ffi.Int magic)>>
      getter_magic;

  external ffi.Pointer<
      ffi.NativeFunction<
          JSValue Function(ffi.Pointer<JSContext> ctx, JSValue this_val,
              JSValue val, ffi.Int magic)>> setter_magic;

  external ffi.Pointer<
      ffi.NativeFunction<
          JSValue Function(
              ffi.Pointer<JSContext> ctx,
              JSValue this_val,
              ffi.Int argc,
              ffi.Pointer<JSValue> argv,
              ffi.Pointer<ffi.Int> pdone,
              ffi.Int magic)>> iterator_next;
}

typedef JSCFunction = ffi.NativeFunction<
    JSValue Function(ffi.Pointer<JSContext> ctx, JSValue this_val, ffi.Int argc,
        ffi.Pointer<JSValue> argv)>;
typedef JSCFunctionData = ffi.NativeFunction<
    JSValue Function(
        ffi.Pointer<JSContext> ctx,
        JSValue this_val,
        ffi.Int argc,
        ffi.Pointer<JSValue> argv,
        ffi.Int magic,
        ffi.Pointer<JSValue> func_data)>;

/// C property definition
final class JSCFunctionListEntry extends ffi.Struct {
  external ffi.Pointer<ffi.Char> name;

  @ffi.Uint8()
  external int prop_flags;

  @ffi.Uint8()
  external int def_type;

  @ffi.Int16()
  external int magic;

  external UnnamedUnion1 u;
}

final class UnnamedUnion1 extends ffi.Union {
  external UnnamedStruct1 func;

  external UnnamedStruct2 getset;

  external UnnamedStruct3 alias;

  external UnnamedStruct4 prop_list;

  external ffi.Pointer<ffi.Char> str;

  @ffi.Int32()
  external int i32;

  @ffi.Int64()
  external int i64;

  @ffi.Double()
  external double f64;
}

final class UnnamedStruct1 extends ffi.Struct {
  /// XXX: should move outside union
  @ffi.Uint8()
  external int length;

  /// XXX: should move outside union
  @ffi.Uint8()
  external int cproto;

  external JSCFunctionType cfunc;
}

final class UnnamedStruct2 extends ffi.Struct {
  external JSCFunctionType get1;

  external JSCFunctionType set1;
}

final class UnnamedStruct3 extends ffi.Struct {
  external ffi.Pointer<ffi.Char> name;

  @ffi.Int()
  external int base;
}

final class UnnamedStruct4 extends ffi.Struct {
  external ffi.Pointer<JSCFunctionListEntry> tab;

  @ffi.Int()
  external int len;
}

/// C module definition
typedef JSModuleInitFunc = ffi.NativeFunction<
    ffi.Int Function(ffi.Pointer<JSContext> ctx, ffi.Pointer<JSModuleDef> m)>;

const int JS_TAG_FIRST = -9;

const int JS_TAG_BIG_INT = -9;

const int JS_TAG_SYMBOL = -8;

const int JS_TAG_STRING = -7;

const int JS_TAG_STRING_ROPE = -6;

const int JS_TAG_MODULE = -3;

const int JS_TAG_FUNCTION_BYTECODE = -2;

const int JS_TAG_OBJECT = -1;

const int JS_TAG_INT = 0;

const int JS_TAG_BOOL = 1;

const int JS_TAG_NULL = 2;

const int JS_TAG_UNDEFINED = 3;

const int JS_TAG_UNINITIALIZED = 4;

const int JS_TAG_CATCH_OFFSET = 5;

const int JS_TAG_EXCEPTION = 6;

const int JS_TAG_SHORT_BIG_INT = 7;

const int JS_TAG_FLOAT64 = 8;

const int JS_LIMB_BITS = 64;

const int JS_SHORT_BIG_INT_BITS = 64;

const int JS_PROP_CONFIGURABLE = 1;

const int JS_PROP_WRITABLE = 2;

const int JS_PROP_ENUMERABLE = 4;

const int JS_PROP_C_W_E = 7;

const int JS_PROP_LENGTH = 8;

const int JS_PROP_TMASK = 48;

const int JS_PROP_NORMAL = 0;

const int JS_PROP_GETSET = 16;

const int JS_PROP_VARREF = 32;

const int JS_PROP_AUTOINIT = 48;

const int JS_PROP_HAS_SHIFT = 8;

const int JS_PROP_HAS_CONFIGURABLE = 256;

const int JS_PROP_HAS_WRITABLE = 512;

const int JS_PROP_HAS_ENUMERABLE = 1024;

const int JS_PROP_HAS_GET = 2048;

const int JS_PROP_HAS_SET = 4096;

const int JS_PROP_HAS_VALUE = 8192;

const int JS_PROP_THROW = 16384;

const int JS_PROP_THROW_STRICT = 32768;

const int JS_PROP_NO_ADD = 65536;

const int JS_PROP_NO_EXOTIC = 131072;

const int JS_DEFAULT_STACK_SIZE = 1048576;

const int JS_EVAL_TYPE_GLOBAL = 0;

const int JS_EVAL_TYPE_MODULE = 1;

const int JS_EVAL_TYPE_DIRECT = 2;

const int JS_EVAL_TYPE_INDIRECT = 3;

const int JS_EVAL_TYPE_MASK = 3;

const int JS_EVAL_FLAG_STRICT = 8;

const int JS_EVAL_FLAG_COMPILE_ONLY = 32;

const int JS_EVAL_FLAG_BACKTRACE_BARRIER = 64;

const int JS_EVAL_FLAG_ASYNC = 128;

const int JS_ATOM_NULL = 0;

const int JS_CALL_FLAG_CONSTRUCTOR = 1;

const int JS_INVALID_CLASS_ID = 0;

const int JS_GPN_STRING_MASK = 1;

const int JS_GPN_SYMBOL_MASK = 2;

const int JS_GPN_PRIVATE_MASK = 4;

const int JS_GPN_ENUM_ONLY = 16;

const int JS_GPN_SET_ENUM = 32;

const int JS_PARSE_JSON_EXT = 1;

const int JS_STRIP_SOURCE = 1;

const int JS_STRIP_DEBUG = 2;

const int JS_WRITE_OBJ_BYTECODE = 1;

const int JS_WRITE_OBJ_BSWAP = 2;

const int JS_WRITE_OBJ_SAB = 4;

const int JS_WRITE_OBJ_REFERENCE = 8;

const int JS_READ_OBJ_BYTECODE = 1;

const int JS_READ_OBJ_ROM_DATA = 2;

const int JS_READ_OBJ_SAB = 4;

const int JS_READ_OBJ_REFERENCE = 8;

const int JS_DEF_CFUNC = 0;

const int JS_DEF_CGETSET = 1;

const int JS_DEF_CGETSET_MAGIC = 2;

const int JS_DEF_PROP_STRING = 3;

const int JS_DEF_PROP_INT32 = 4;

const int JS_DEF_PROP_INT64 = 5;

const int JS_DEF_PROP_DOUBLE = 6;

const int JS_DEF_PROP_UNDEFINED = 7;

const int JS_DEF_OBJECT = 8;

const int JS_DEF_ALIAS = 9;
