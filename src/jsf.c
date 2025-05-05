/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

#include <string.h>
#include <stdlib.h>
#include "quickjs.h"
#include "jsf.h"

// static JSRuntime* runtime = NULL;
// static JSContext* context = NULL;

// FFI_PLUGIN_EXPORT void qjs_init() {
//     if (!runtime) {
//         runtime = JS_NewRuntime();
//         context = JS_NewContext(runtime);
//     }
// }

// FFI_PLUGIN_EXPORT const char* qjs_eval(const char* code) {
//     if (!context) return "QuickJS not initialized";

//     JSValue result = JS_Eval(context, code, strlen(code), "<eval>", JS_EVAL_TYPE_GLOBAL);
//     if (JS_IsException(result)) {
//         JSValue err = JS_GetException(context);
//         const char* err_str = JS_ToCString(context, err);
//         JS_FreeValue(context, err);
//         return err_str;
//     }

//     const char* str = JS_ToCString(context, result);
//     JS_FreeValue(context, result);
//     return str;
// }

// FFI_PLUGIN_EXPORT void qjs_free_result(const char* str) {
//     if (str && context) {
//         JS_FreeCString(context, str);
//     }
// }

// FFI_PLUGIN_EXPORT void qjs_exec_init_script(const char* code) {
//     if (!context) return;
//     JS_Eval(context, code, strlen(code), "<init>", JS_EVAL_TYPE_GLOBAL);
// }

// FFI_PLUGIN_EXPORT void qjs_cleanup() {
//     if (context) JS_FreeContext(context);
//     if (runtime) JS_FreeRuntime(runtime);
//     context = NULL;
//     runtime = NULL;
// }
