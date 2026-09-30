/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct JSContext JSContext;
typedef struct JSModuleDef JSModuleDef;

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <sys/time.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#elif defined(__APPLE__)
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"), used))
#elif defined(__GNUC__) || defined(__clang__)
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT JSModuleDef *JS_LoadMjsModule(JSContext *ctx, const char *module_name, const char *module_source);
FFI_PLUGIN_EXPORT void JS_InitConsole(JSContext *ctx);

typedef struct JSFRuntime JSFRuntime;
typedef struct JSFValue JSFValue;

typedef char *(*JSFDartFunction)(void *opaque, const char *args_json);
typedef void (*JSFDartFreeFunction)(void *opaque, char *result);
typedef JSFValue *(*JSFDartHandleFunction)(void *opaque, JSFValue **argv, int32_t argc);

typedef enum JSFValueType
{
    JSF_VALUE_EXCEPTION = -1,
    JSF_VALUE_UNDEFINED = 0,
    JSF_VALUE_NULL = 1,
    JSF_VALUE_BOOL = 2,
    JSF_VALUE_INT = 3,
    JSF_VALUE_FLOAT = 4,
    JSF_VALUE_BIGINT = 5,
    JSF_VALUE_STRING = 6,
    JSF_VALUE_ARRAY = 7,
    JSF_VALUE_OBJECT = 8,
    JSF_VALUE_FUNCTION = 9,
    JSF_VALUE_PROMISE = 10,
    JSF_VALUE_ARRAY_BUFFER = 11,
    JSF_VALUE_UNKNOWN = 100
} JSFValueType;

FFI_PLUGIN_EXPORT JSFRuntime *JSF_RuntimeNew(void);
/* Serialize calls per runtime. All owned JSFValue handles must be freed first.
 * Freeing a runtime during execution or with live handles is rejected; inspect
 * JSF_RuntimeLastError and retry once the outer call/handle lifetime ends. */
FFI_PLUGIN_EXPORT void JSF_RuntimeFree(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT void JSF_RuntimeSetMemoryLimit(JSFRuntime *runtime, size_t limit);
FFI_PLUGIN_EXPORT void JSF_RuntimeSetMaxStackSize(JSFRuntime *runtime, size_t stack_size);
FFI_PLUGIN_EXPORT void JSF_RuntimeSetTimeout(JSFRuntime *runtime, int32_t timeout_ms);
FFI_PLUGIN_EXPORT void JSF_RuntimeClearTimeout(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT int32_t JSF_RuntimeExecutePendingJobs(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT const char *JSF_RuntimeLastError(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT int32_t JSF_RuntimeRegisterModule(JSFRuntime *runtime, const char *module_name, const char *module_source);
FFI_PLUGIN_EXPORT int32_t JSF_RuntimeRegisterModuleAlias(JSFRuntime *runtime, const char *module_name, const char *resolved_name);
FFI_PLUGIN_EXPORT void JSF_RuntimeClearModules(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT int32_t JSF_RuntimeResolveDartFuture(JSFRuntime *runtime, int32_t future_id, const char *result_json, int32_t is_error);

FFI_PLUGIN_EXPORT JSFValue *JSF_Eval(JSFRuntime *runtime, const char *code, const char *filename, int32_t module);
FFI_PLUGIN_EXPORT JSFValue *JSF_LoadModule(JSFRuntime *runtime, const char *module_name, const char *module_source);
FFI_PLUGIN_EXPORT JSFValue *JSF_GetGlobal(JSFRuntime *runtime, const char *name);
FFI_PLUGIN_EXPORT int32_t JSF_SetGlobal(JSFRuntime *runtime, const char *name, JSFValue *value);
FFI_PLUGIN_EXPORT JSFValue *JSF_Call(JSFRuntime *runtime, JSFValue *function, JSFValue *this_value, JSFValue **argv, int32_t argc);
FFI_PLUGIN_EXPORT JSFValue *JSF_CallGlobal(JSFRuntime *runtime, const char *name, JSFValue **argv, int32_t argc);
FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartFunction(JSFRuntime *runtime, const char *name, JSFDartFunction callback, JSFDartFreeFunction free_result, void *opaque);
FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartHandleFunction(JSFRuntime *runtime, const char *name, JSFDartHandleFunction callback, void *opaque);

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewUndefined(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewNull(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewBool(JSFRuntime *runtime, int32_t value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewInt64(JSFRuntime *runtime, int64_t value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewFloat64(JSFRuntime *runtime, double value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewString(JSFRuntime *runtime, const char *value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewBigInt(JSFRuntime *runtime, const char *decimal_value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewJson(JSFRuntime *runtime, const char *json);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewTransferJson(JSFRuntime *runtime, const char *json);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewArray(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewObject(JSFRuntime *runtime);

FFI_PLUGIN_EXPORT void JSF_ValueFree(JSFValue *value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueDup(JSFValue *value);
FFI_PLUGIN_EXPORT JSFValueType JSF_ValueType(JSFValue *value);
FFI_PLUGIN_EXPORT int32_t JSF_ValueToBool(JSFValue *value);
FFI_PLUGIN_EXPORT int64_t JSF_ValueToInt64(JSFValue *value);
FFI_PLUGIN_EXPORT double JSF_ValueToFloat64(JSFValue *value);
FFI_PLUGIN_EXPORT char *JSF_ValueToCString(JSFValue *value);
FFI_PLUGIN_EXPORT char *JSF_ValueToJson(JSFValue *value);
FFI_PLUGIN_EXPORT int32_t JSF_ValueArrayLength(JSFValue *value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueArrayGet(JSFValue *value, uint32_t index);
FFI_PLUGIN_EXPORT int32_t JSF_ValueArraySet(JSFValue *value, uint32_t index, JSFValue *element);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueObjectGet(JSFValue *value, const char *key);
FFI_PLUGIN_EXPORT int32_t JSF_ValueObjectSet(JSFValue *value, const char *key, JSFValue *property);
FFI_PLUGIN_EXPORT int32_t JSF_ValuePromiseState(JSFValue *value);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValuePromiseResult(JSFValue *value);
FFI_PLUGIN_EXPORT void JSF_FreeCString(char *value);

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeExecutePendingJobsMax(JSFRuntime *runtime, int32_t max_jobs);

FFI_PLUGIN_EXPORT const char *JSF_RuntimeLastErrorJson(JSFRuntime *runtime);

FFI_PLUGIN_EXPORT JSFValue *JSF_GetGlobalJson(JSFRuntime *runtime, const char *name);

FFI_PLUGIN_EXPORT int32_t JSF_SetGlobalJson(JSFRuntime *runtime, const char *name, JSFValue *value);

FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartFunctionJson(JSFRuntime *runtime, const char *name, JSFDartFunction callback, JSFDartFreeFunction free_result, void *opaque);

FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartHandleFunctionJson(JSFRuntime *runtime, const char *name, JSFDartHandleFunction callback, void *opaque);

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueObjectGetJson(JSFValue *value, const char *key);

FFI_PLUGIN_EXPORT int32_t JSF_ValueObjectSetJson(JSFValue *value, const char *key, JSFValue *property);

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewArrayBuffer(JSFRuntime *runtime, const uint8_t *bytes, size_t length);
/* Allocates a zero-filled, QuickJS-owned ArrayBuffer and returns its writable
 * storage in data. On failure, returns NULL and sets *data to NULL.
 * The storage counts toward the runtime memory limit. Fill it synchronously
 * before exposing the value to JS; never retain the pointer across JS calls,
 * transfer/detachment, value release or runtime destruction. Do not free it. */
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueAllocArrayBuffer(JSFRuntime *runtime, size_t length, uint8_t **data);

FFI_PLUGIN_EXPORT const uint8_t *JSF_ValueArrayBufferData(JSFValue *value, size_t *length);

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeResolveDartFutureValue(JSFRuntime *runtime, int32_t future_id, JSFValue *value, int32_t is_error);

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeRegisterModuleLen(JSFRuntime *runtime, const char *module_name, const char *module_source, size_t source_len);

FFI_PLUGIN_EXPORT JSFValue *JSF_EvalLen(JSFRuntime *runtime, const char *code, size_t code_len, const char *filename, int32_t module);

FFI_PLUGIN_EXPORT JSFValue *JSF_LoadModuleLen(JSFRuntime *runtime, const char *module_name, const char *module_source, size_t source_len);

/* ABI 2 adds checked runtime ownership, per-call budgets and callback errors. */
FFI_PLUGIN_EXPORT int32_t JSF_ABIVersion(void);
FFI_PLUGIN_EXPORT const char *JSF_EngineVersion(void);
FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewExceptionJson(JSFRuntime *runtime, const char *json);

FFI_PLUGIN_EXPORT void JSF_RuntimeSetRejectionTracking(JSFRuntime *runtime, int32_t enabled);
FFI_PLUGIN_EXPORT JSFValue *JSF_RuntimeTakeRejection(JSFRuntime *runtime);
FFI_PLUGIN_EXPORT int32_t JSF_ValueObservePromise(JSFValue *value);
FFI_PLUGIN_EXPORT int32_t JSF_RuntimeUnregisterCallback(JSFRuntime *runtime, void *opaque);
FFI_PLUGIN_EXPORT char *JSF_RuntimeStatistics(JSFRuntime *runtime);
