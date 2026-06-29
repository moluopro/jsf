/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

#include "quickjs.h"
#include "jsf.h"

typedef struct JSFDartCallbackEntry
{
    int32_t id;
    JSFDartFunction callback;
    JSFDartFreeFunction free_result;
    JSFDartHandleFunction handle_callback;
    void *opaque;
    struct JSFDartCallbackEntry *next;
} JSFDartCallbackEntry;

typedef struct JSFModuleEntry
{
    char *name;
    char *source;
    struct JSFModuleEntry *next;
} JSFModuleEntry;

typedef struct JSFModuleAliasEntry
{
    char *name;
    char *resolved_name;
    struct JSFModuleAliasEntry *next;
} JSFModuleAliasEntry;

typedef struct JSFDartFutureEntry
{
    int32_t id;
    JSValue resolving_funcs[2];
    struct JSFDartFutureEntry *next;
} JSFDartFutureEntry;

struct JSFRuntime
{
    JSRuntime *runtime;
    JSContext *context;
    char *last_error;
    int64_t deadline_ms;
    int32_t next_callback_id;
    JSFDartCallbackEntry *callbacks;
    JSFModuleEntry *modules;
    JSFModuleAliasEntry *module_aliases;
    JSFDartFutureEntry *dart_futures;
};

struct JSFValue
{
    JSFRuntime *owner;
    JSValue value;
};

static int64_t jsf_now_ms(void)
{
#if _WIN32
    return (int64_t)GetTickCount64();
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((int64_t)tv.tv_sec * 1000) + ((int64_t)tv.tv_usec / 1000);
#endif
}

static char *jsf_strdup(const char *value)
{
    if (!value)
        return NULL;
    size_t len = strlen(value);
    char *copy = (char *)malloc(len + 1);
    if (!copy)
        return NULL;
    memcpy(copy, value, len + 1);
    return copy;
}

static void jsf_set_last_error(JSFRuntime *runtime, const char *message)
{
    if (!runtime)
        return;
    free(runtime->last_error);
    runtime->last_error = jsf_strdup(message ? message : "Unknown JavaScript error");
}

static char *jsf_to_owned_cstring(JSContext *ctx, JSValueConst value)
{
    const char *raw = JS_ToCString(ctx, value);
    if (!raw)
        return NULL;
    char *copy = jsf_strdup(raw);
    JS_FreeCString(ctx, raw);
    return copy;
}

static void jsf_capture_exception(JSFRuntime *runtime)
{
    if (!runtime || !runtime->context)
        return;

    JSContext *ctx = runtime->context;
    JSValue exception = JS_GetException(ctx);
    JSValue stack = JS_GetPropertyStr(ctx, exception, "stack");
    char *message = NULL;

    if (!JS_IsUndefined(stack) && !JS_IsNull(stack))
        message = jsf_to_owned_cstring(ctx, stack);
    if (!message)
        message = jsf_to_owned_cstring(ctx, exception);

    jsf_set_last_error(runtime, message ? message : "JavaScript exception");
    free(message);
    JS_FreeValue(ctx, stack);
    JS_FreeValue(ctx, exception);
}

static JSFValue *jsf_value_new_owned(JSFRuntime *runtime, JSValue value)
{
    if (!runtime)
    {
        return NULL;
    }
    JSFValue *ref = (JSFValue *)calloc(1, sizeof(JSFValue));
    if (!ref)
    {
        JS_FreeValue(runtime->context, value);
        jsf_set_last_error(runtime, "Out of memory allocating JSFValue");
        return NULL;
    }
    ref->owner = runtime;
    ref->value = value;
    return ref;
}

static int jsf_interrupt_handler(JSRuntime *rt, void *opaque)
{
    (void)rt;
    JSFRuntime *runtime = (JSFRuntime *)opaque;
    if (!runtime || runtime->deadline_ms <= 0)
        return 0;
    return jsf_now_ms() > runtime->deadline_ms;
}

static JSFDartCallbackEntry *jsf_find_callback(JSFRuntime *runtime, int32_t id)
{
    JSFDartCallbackEntry *entry = runtime ? runtime->callbacks : NULL;
    while (entry)
    {
        if (entry->id == id)
            return entry;
        entry = entry->next;
    }
    return NULL;
}

static JSFModuleEntry *jsf_find_module(JSFRuntime *runtime, const char *name)
{
    JSFModuleEntry *entry = runtime ? runtime->modules : NULL;
    while (entry)
    {
        if (entry->name && !strcmp(entry->name, name))
            return entry;
        entry = entry->next;
    }
    return NULL;
}

static JSFModuleAliasEntry *jsf_find_module_alias(JSFRuntime *runtime, const char *name)
{
    JSFModuleAliasEntry *entry = runtime ? runtime->module_aliases : NULL;
    while (entry)
    {
        if (entry->name && !strcmp(entry->name, name))
            return entry;
        entry = entry->next;
    }
    return NULL;
}

static void jsf_free_modules(JSFRuntime *runtime)
{
    if (!runtime)
        return;
    JSFModuleEntry *entry = runtime->modules;
    while (entry)
    {
        JSFModuleEntry *next = entry->next;
        free(entry->name);
        free(entry->source);
        free(entry);
        entry = next;
    }
    runtime->modules = NULL;
}

static void jsf_free_module_aliases(JSFRuntime *runtime)
{
    if (!runtime)
        return;
    JSFModuleAliasEntry *entry = runtime->module_aliases;
    while (entry)
    {
        JSFModuleAliasEntry *next = entry->next;
        free(entry->name);
        free(entry->resolved_name);
        free(entry);
        entry = next;
    }
    runtime->module_aliases = NULL;
}

static const char *jsf_resolve_module_alias(JSFRuntime *runtime, const char *name)
{
    JSFModuleAliasEntry *alias = jsf_find_module_alias(runtime, name);
    return alias && alias->resolved_name ? alias->resolved_name : name;
}

static char *jsf_normalize_relative_module(const char *base_name, const char *module_name)
{
    if (!module_name)
        return NULL;
    if (module_name[0] != '.')
        return jsf_strdup(module_name);

    size_t base_dir_len = 0;
    if (base_name)
    {
        const char *slash = strrchr(base_name, '/');
        if (slash)
            base_dir_len = (size_t)(slash - base_name) + 1;
    }

    size_t raw_len = base_dir_len + strlen(module_name) + 1;
    char *raw = (char *)calloc(raw_len, 1);
    if (!raw)
        return NULL;
    if (base_dir_len > 0)
        memcpy(raw, base_name, base_dir_len);
    strcat(raw, module_name);

    char **segments = (char **)calloc(raw_len, sizeof(char *));
    char *scratch = jsf_strdup(raw);
    free(raw);
    if (!segments || !scratch)
    {
        free(segments);
        free(scratch);
        return NULL;
    }

    int count = 0;
    char *part = strtok(scratch, "/");
    while (part)
    {
        if (!strcmp(part, ".."))
        {
            if (count > 0)
                count--;
        }
        else if (strcmp(part, ".") && strlen(part) > 0)
        {
            segments[count++] = part;
        }
        part = strtok(NULL, "/");
    }

    size_t out_len = 1;
    for (int i = 0; i < count; i++)
        out_len += strlen(segments[i]) + 1;
    char *out = (char *)calloc(out_len, 1);
    if (out)
    {
        for (int i = 0; i < count; i++)
        {
            if (i > 0)
                strcat(out, "/");
            strcat(out, segments[i]);
        }
    }
    free(segments);
    free(scratch);
    return out;
}

static char *jsf_module_normalize(JSContext *ctx, const char *module_base_name, const char *module_name, void *opaque)
{
    JSFRuntime *runtime = (JSFRuntime *)opaque;
    char *normalized = jsf_normalize_relative_module(module_base_name, module_name);
    if (!normalized)
        return NULL;
    const char *resolved = jsf_resolve_module_alias(runtime, normalized);
    size_t len = strlen(resolved);
    char *out = (char *)js_malloc(ctx, len + 1);
    if (out)
        memcpy(out, resolved, len + 1);
    free(normalized);
    return out;
}

static void jsf_free_dart_futures(JSFRuntime *runtime)
{
    if (!runtime || !runtime->context)
        return;
    JSFDartFutureEntry *entry = runtime->dart_futures;
    while (entry)
    {
        JSFDartFutureEntry *next = entry->next;
        JS_FreeValue(runtime->context, entry->resolving_funcs[0]);
        JS_FreeValue(runtime->context, entry->resolving_funcs[1]);
        free(entry);
        entry = next;
    }
    runtime->dart_futures = NULL;
}

static JSFDartFutureEntry *jsf_take_dart_future(JSFRuntime *runtime, int32_t id)
{
    JSFDartFutureEntry **current = runtime ? &runtime->dart_futures : NULL;
    while (current && *current)
    {
        JSFDartFutureEntry *entry = *current;
        if (entry->id == id)
        {
            *current = entry->next;
            entry->next = NULL;
            return entry;
        }
        current = &entry->next;
    }
    return NULL;
}

static int jsf_get_dart_future_id(JSFRuntime *runtime, JSValueConst value, int32_t *future_id)
{
    if (!runtime || !runtime->context || !JS_IsObject(value))
        return 0;
    JSContext *ctx = runtime->context;
    JSValue type = JS_GetPropertyStr(ctx, value, "$jsf.type");
    const char *type_str = JS_ToCString(ctx, type);
    int is_future = type_str && strcmp(type_str, "DartFuture") == 0;
    if (type_str)
        JS_FreeCString(ctx, type_str);
    JS_FreeValue(ctx, type);
    if (!is_future)
        return 0;

    JSValue id = JS_GetPropertyStr(ctx, value, "id");
    int32_t out = 0;
    int ret = JS_ToInt32(ctx, &out, id);
    JS_FreeValue(ctx, id);
    if (ret != 0)
        return 0;
    *future_id = out;
    return 1;
}

static JSValue jsf_create_dart_future_promise(JSFRuntime *runtime, int32_t future_id)
{
    JSValue resolving_funcs[2];
    JSValue promise = JS_NewPromiseCapability(runtime->context, resolving_funcs);
    if (JS_IsException(promise))
        return promise;

    JSFDartFutureEntry *entry = (JSFDartFutureEntry *)calloc(1, sizeof(JSFDartFutureEntry));
    if (!entry)
    {
        JS_FreeValue(runtime->context, resolving_funcs[0]);
        JS_FreeValue(runtime->context, resolving_funcs[1]);
        JS_FreeValue(runtime->context, promise);
        return JS_ThrowOutOfMemory(runtime->context);
    }

    entry->id = future_id;
    entry->resolving_funcs[0] = resolving_funcs[0];
    entry->resolving_funcs[1] = resolving_funcs[1];
    entry->next = runtime->dart_futures;
    runtime->dart_futures = entry;
    return promise;
}

static JSValue jsf_replace_dart_future(JSFRuntime *runtime, JSValue value)
{
    int32_t future_id = 0;
    if (!jsf_get_dart_future_id(runtime, value, &future_id))
        return value;
    JS_FreeValue(runtime->context, value);
    return jsf_create_dart_future_promise(runtime, future_id);
}

static JSModuleDef *jsf_module_loader(JSContext *ctx, const char *module_name, void *opaque)
{
    JSFRuntime *runtime = (JSFRuntime *)opaque;
    const char *resolved_name = jsf_resolve_module_alias(runtime, module_name);
    JSFModuleEntry *entry = jsf_find_module(runtime, resolved_name);
    if (!entry)
    {
        JS_ThrowReferenceError(ctx, "could not load module '%s'", resolved_name);
        return NULL;
    }

    JSValue func_val = JS_Eval(ctx, entry->source, strlen(entry->source), resolved_name,
                               JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(func_val))
        return NULL;

    JSModuleDef *module = JS_VALUE_GET_PTR(func_val);
    JS_FreeValue(ctx, func_val);
    return module;
}

static JSValue jsf_json_stringify(JSContext *ctx, JSValueConst value)
{
    const char *source =
        "(function(v){"
        "const seen=[];"
        "function enc(x){"
        "if(x===undefined)return {'$jsf.type':'Undefined'};"
        "if(typeof x==='bigint')return {'$jsf.type':'BigInt','value':x.toString()};"
        "if(typeof x==='number'){"
        "if(Number.isNaN(x))return {'$jsf.type':'Number','value':'NaN'};"
        "if(x===Infinity)return {'$jsf.type':'Number','value':'Infinity'};"
        "if(x===-Infinity)return {'$jsf.type':'Number','value':'-Infinity'};"
        "if(Object.is(x,-0))return {'$jsf.type':'Number','value':'-0'};"
        "return x;"
        "}"
        "if(typeof x==='function')return {'$jsf.type':'Function'};"
        "if(typeof x==='symbol')return {'$jsf.type':'Symbol','value':String(x)};"
        "if(x===null||typeof x!=='object')return x;"
        "if(seen.indexOf(x)>=0)throw new TypeError('circular reference');"
        "seen.push(x);"
        "try{"
        "if(x instanceof Date)return {'$jsf.type':'Date','value':x.toISOString()};"
        "if(x instanceof RegExp)return {'$jsf.type':'RegExp','source':x.source,'flags':x.flags};"
        "if(x instanceof Error)return {'$jsf.type':'Error','name':x.name,'message':x.message,'stack':x.stack};"
        "if(x instanceof Map)return {'$jsf.type':'Map','entries':Array.from(x.entries(),function(e){return [enc(e[0]),enc(e[1])];})};"
        "if(x instanceof Set)return {'$jsf.type':'Set','values':Array.from(x.values(),enc)};"
        "if(typeof ArrayBuffer!=='undefined'&&ArrayBuffer.isView(x))return {'$jsf.type':'TypedArray','name':x.constructor.name,'values':Array.from(x)};"
        "if(typeof ArrayBuffer!=='undefined'&&x instanceof ArrayBuffer)return {'$jsf.type':'ArrayBuffer','bytes':Array.from(new Uint8Array(x))};"
        "if(Array.isArray(x)){var a=[];for(var i=0;i<x.length;i++){a.push(Object.prototype.hasOwnProperty.call(x,i)?enc(x[i]):{'$jsf.type':'ArrayHole'});}return a;}"
        "var out={};Object.keys(x).forEach(function(k){out[k]=enc(x[k]);});return out;"
        "}finally{seen.pop();}"
        "}"
        "return JSON.stringify(enc(v));"
        "})";

    JSValue fn = JS_Eval(ctx, source, strlen(source), "<jsf.stringify>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(fn))
        return fn;

    JSValue args[1] = {JS_DupValue(ctx, value)};
    JSValue result = JS_Call(ctx, fn, JS_UNDEFINED, 1, args);
    JS_FreeValue(ctx, args[0]);
    JS_FreeValue(ctx, fn);
    return result;
}

static char *jsf_value_to_json_owned(JSFRuntime *runtime, JSValueConst value)
{
    JSValue json_value = jsf_json_stringify(runtime->context, value);
    if (JS_IsException(json_value))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }

    if (JS_IsUndefined(json_value))
    {
        JS_FreeValue(runtime->context, json_value);
        return jsf_strdup("null");
    }

    char *json = jsf_to_owned_cstring(runtime->context, json_value);
    JS_FreeValue(runtime->context, json_value);
    return json;
}

static JSValue jsf_parse_json(JSFRuntime *runtime, const char *json)
{
    if (!json)
        return JS_NULL;
    JSValue parsed = JS_ParseJSON(runtime->context, json, strlen(json), "<dart>");
    if (JS_IsException(parsed))
        jsf_capture_exception(runtime);
    return parsed;
}

static JSValue jsf_parse_transfer_json(JSFRuntime *runtime, const char *json)
{
    if (!runtime || !runtime->context)
        return JS_EXCEPTION;

    JSValue parsed = jsf_parse_json(runtime, json);
    if (JS_IsException(parsed))
        return parsed;

    const char *source =
        "(function revive(v){"
        "function r(x){"
        "if(Array.isArray(x)){var a=[];for(var i=0;i<x.length;i++){var item=x[i];if(item&&item['$jsf.type']==='ArrayHole'){a.length=i+1;}else{a[i]=r(item);}}return a;}"
        "if(!x||typeof x!=='object')return x;"
        "var t=x['$jsf.type'];"
        "if(t==='Undefined')return undefined;"
        "if(t==='BigInt')return BigInt(x.value);"
        "if(t==='Number'){if(x.value==='NaN')return NaN;if(x.value==='Infinity')return Infinity;if(x.value==='-Infinity')return -Infinity;if(x.value==='-0')return -0;return Number(x.value);}"
        "if(t==='Date')return new Date(x.value);"
        "if(t==='RegExp')return new RegExp(x.source||'',x.flags||'');"
        "if(t==='Error'){var e=new Error(x.message||'');e.name=x.name||'Error';if(x.stack)e.stack=x.stack;return e;}"
        "if(t==='Map')return new Map((x.entries||[]).map(function(e){return [r(e[0]),r(e[1])];}));"
        "if(t==='Set')return new Set((x.values||[]).map(r));"
        "if(t==='ArrayBuffer')return new Uint8Array(x.bytes||[]).buffer;"
        "if(t==='TypedArray'){var vals=x.values||[];var C=globalThis[x.name]||Array;try{return new C(vals);}catch(_){return vals;}}"
        "if(t==='DartFuture')return {'$jsf.type':'DartFuture','id':x.id};"
        "var out={};Object.keys(x).forEach(function(k){if(k!=='$jsf.type')out[k]=r(x[k]);});return out;"
        "}"
        "return r(v);"
        "})";

    JSValue fn = JS_Eval(runtime->context, source, strlen(source), "<jsf.revive>", JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(fn))
    {
        JS_FreeValue(runtime->context, parsed);
        jsf_capture_exception(runtime);
        return JS_EXCEPTION;
    }

    JSValue args[1] = {parsed};
    JSValue result = JS_Call(runtime->context, fn, JS_UNDEFINED, 1, args);
    JS_FreeValue(runtime->context, args[0]);
    JS_FreeValue(runtime->context, fn);
    if (JS_IsException(result))
        jsf_capture_exception(runtime);
    if (!JS_IsException(result))
        result = jsf_replace_dart_future(runtime, result);
    return result;
}

static JSValue jsf_dart_callback(JSContext *ctx, JSValueConst this_val, int argc,
                                 JSValueConst *argv, int magic, JSValue *func_data)
{
    (void)this_val;
    (void)magic;

    int32_t callback_id = 0;
    if (JS_ToInt32(ctx, &callback_id, func_data[0]) != 0)
        return JS_ThrowInternalError(ctx, "Invalid Dart callback id");

    JSFRuntime *runtime = (JSFRuntime *)JS_GetContextOpaque(ctx);
    JSFDartCallbackEntry *entry = jsf_find_callback(runtime, callback_id);
    if (!entry || (!entry->callback && !entry->handle_callback))
        return JS_ThrowInternalError(ctx, "Dart callback is not registered");

    if (entry->handle_callback)
    {
        JSFValue **wrapped_args = NULL;
        if (argc > 0)
        {
            wrapped_args = (JSFValue **)calloc((size_t)argc, sizeof(JSFValue *));
            if (!wrapped_args)
                return JS_ThrowOutOfMemory(ctx);
        }

        for (int i = 0; i < argc; i++)
        {
            wrapped_args[i] = jsf_value_new_owned(runtime, JS_DupValue(ctx, argv[i]));
            if (!wrapped_args[i])
            {
                for (int j = 0; j < i; j++)
                    JSF_ValueFree(wrapped_args[j]);
                free(wrapped_args);
                return JS_ThrowOutOfMemory(ctx);
            }
        }

        JSFValue *callback_result = entry->handle_callback(entry->opaque, wrapped_args, argc);

        for (int i = 0; i < argc; i++)
            JSF_ValueFree(wrapped_args[i]);
        free(wrapped_args);

        if (!callback_result)
            return JS_UNDEFINED;

        JSValue result = JS_DupValue(ctx, callback_result->value);
        JSF_ValueFree(callback_result);
        return jsf_replace_dart_future(runtime, result);
    }

    JSValue args_array = JS_NewArray(ctx);
    for (int i = 0; i < argc; i++)
    {
        JS_SetPropertyUint32(ctx, args_array, (uint32_t)i, JS_DupValue(ctx, argv[i]));
    }

    char *args_json = jsf_value_to_json_owned(runtime, args_array);
    JS_FreeValue(ctx, args_array);
    if (!args_json)
        return JS_EXCEPTION;

    char *result_json = entry->callback(entry->opaque, args_json);
    free(args_json);

    if (!result_json)
        return JS_UNDEFINED;

    JSValue result = jsf_parse_transfer_json(runtime, result_json);
    if (entry->free_result)
        entry->free_result(entry->opaque, result_json);

    return jsf_replace_dart_future(runtime, result);
}

FFI_PLUGIN_EXPORT JSModuleDef *JS_LoadMjsModule(JSContext *ctx, const char *module_name, const char *module_source)
{
    if (!module_source || !module_name)
    {
        JS_ThrowReferenceError(ctx, "Invalid module name or source");
        return NULL;
    }

    JSValue func_val = JS_Eval(ctx, module_source, strlen(module_source), module_name,
                               JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(func_val))
        return NULL;

    JSModuleDef *module = JS_VALUE_GET_PTR(func_val);

    JSValue ret = JS_EvalFunction(ctx, func_val);
    if (JS_IsException(ret))
    {
        JS_FreeValue(ctx, ret);
        return NULL;
    }
    JS_FreeValue(ctx, ret);
    return module;
}

static JSValue js_console_log(JSContext *ctx, JSValueConst this_val,
                              int argc, JSValueConst *argv)
{
    for (int i = 0; i < argc; i++)
    {
        const char *str = JS_ToCString(ctx, argv[i]);
        if (str)
        {
            printf("%s", str);
            JS_FreeCString(ctx, str);
        }
        if (i != argc - 1)
            putchar(' ');
    }
    putchar('\n');
    return JS_UNDEFINED;
}

static JSValue js_console_warn(JSContext *ctx, JSValueConst this_val,
                               int argc, JSValueConst *argv)
{
    fputs("Warning: ", stderr);
    for (int i = 0; i < argc; i++)
    {
        const char *str = JS_ToCString(ctx, argv[i]);
        if (str)
        {
            fputs(str, stderr);
            JS_FreeCString(ctx, str);
        }
        if (i != argc - 1)
            fputc(' ', stderr);
    }
    fputc('\n', stderr);
    return JS_UNDEFINED;
}

static JSValue js_console_error(JSContext *ctx, JSValueConst this_val,
                                int argc, JSValueConst *argv)
{
    fputs("Error: ", stderr);
    for (int i = 0; i < argc; i++)
    {
        const char *str = JS_ToCString(ctx, argv[i]);
        if (str)
        {
            fputs(str, stderr);
            JS_FreeCString(ctx, str);
        }
        if (i != argc - 1)
            fputc(' ', stderr);
    }
    fputc('\n', stderr);
    return JS_UNDEFINED;
}

FFI_PLUGIN_EXPORT void JS_InitConsole(JSContext *ctx)
{
    JSValue global_obj = JS_GetGlobalObject(ctx);
    JSValue console = JS_NewObject(ctx);

    JS_SetPropertyStr(ctx, console, "log",
                      JS_NewCFunction(ctx, js_console_log, "log", 1));
    JS_SetPropertyStr(ctx, console, "warn",
                      JS_NewCFunction(ctx, js_console_warn, "warn", 1));
    JS_SetPropertyStr(ctx, console, "error",
                      JS_NewCFunction(ctx, js_console_error, "error", 1));

    JS_SetPropertyStr(ctx, global_obj, "console", console);
    JS_FreeValue(ctx, global_obj);
}

FFI_PLUGIN_EXPORT JSFRuntime *JSF_RuntimeNew(void)
{
    JSFRuntime *runtime = (JSFRuntime *)calloc(1, sizeof(JSFRuntime));
    if (!runtime)
        return NULL;

    runtime->runtime = JS_NewRuntime();
    if (!runtime->runtime)
    {
        free(runtime);
        return NULL;
    }

    runtime->context = JS_NewContext(runtime->runtime);
    if (!runtime->context)
    {
        JS_FreeRuntime(runtime->runtime);
        free(runtime);
        return NULL;
    }

    runtime->next_callback_id = 1;
    JS_SetContextOpaque(runtime->context, runtime);
    JS_SetInterruptHandler(runtime->runtime, jsf_interrupt_handler, runtime);
    JS_SetModuleLoaderFunc(runtime->runtime, jsf_module_normalize, jsf_module_loader, runtime);
    JS_InitConsole(runtime->context);
    return runtime;
}

FFI_PLUGIN_EXPORT void JSF_RuntimeFree(JSFRuntime *runtime)
{
    if (!runtime)
        return;

    JSFDartCallbackEntry *entry = runtime->callbacks;
    while (entry)
    {
        JSFDartCallbackEntry *next = entry->next;
        free(entry);
        entry = next;
    }
    jsf_free_modules(runtime);
    jsf_free_module_aliases(runtime);
    jsf_free_dart_futures(runtime);

    if (runtime->context)
        JS_FreeContext(runtime->context);
    if (runtime->runtime)
        JS_FreeRuntime(runtime->runtime);
    free(runtime->last_error);
    free(runtime);
}

FFI_PLUGIN_EXPORT void JSF_RuntimeSetMemoryLimit(JSFRuntime *runtime, size_t limit)
{
    if (runtime && runtime->runtime)
        JS_SetMemoryLimit(runtime->runtime, limit);
}

FFI_PLUGIN_EXPORT void JSF_RuntimeSetMaxStackSize(JSFRuntime *runtime, size_t stack_size)
{
    if (runtime && runtime->runtime)
        JS_SetMaxStackSize(runtime->runtime, stack_size);
}

FFI_PLUGIN_EXPORT void JSF_RuntimeSetTimeout(JSFRuntime *runtime, int32_t timeout_ms)
{
    if (!runtime)
        return;
    runtime->deadline_ms = timeout_ms <= 0 ? 0 : jsf_now_ms() + timeout_ms;
}

FFI_PLUGIN_EXPORT void JSF_RuntimeClearTimeout(JSFRuntime *runtime)
{
    if (runtime)
        runtime->deadline_ms = 0;
}

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeExecutePendingJobs(JSFRuntime *runtime)
{
    if (!runtime || !runtime->runtime)
        return -1;

    int32_t count = 0;
    JSContext *ctx = NULL;
    for (;;)
    {
        int ret = JS_ExecutePendingJob(runtime->runtime, &ctx);
        if (ret <= 0)
        {
            if (ret < 0)
                jsf_capture_exception(runtime);
            return ret < 0 ? ret : count;
        }
        count++;
    }
}

FFI_PLUGIN_EXPORT const char *JSF_RuntimeLastError(JSFRuntime *runtime)
{
    if (!runtime || !runtime->last_error)
        return "";
    return runtime->last_error;
}

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeRegisterModule(JSFRuntime *runtime, const char *module_name, const char *module_source)
{
    if (!runtime || !module_name || !module_source)
        return -1;

    JSFModuleEntry *entry = jsf_find_module(runtime, module_name);
    if (entry)
    {
        char *source = jsf_strdup(module_source);
        if (!source)
        {
            jsf_set_last_error(runtime, "Out of memory registering JavaScript module");
            return -1;
        }
        free(entry->source);
        entry->source = source;
        return 0;
    }

    entry = (JSFModuleEntry *)calloc(1, sizeof(JSFModuleEntry));
    if (!entry)
    {
        jsf_set_last_error(runtime, "Out of memory registering JavaScript module");
        return -1;
    }
    entry->name = jsf_strdup(module_name);
    entry->source = jsf_strdup(module_source);
    if (!entry->name || !entry->source)
    {
        free(entry->name);
        free(entry->source);
        free(entry);
        jsf_set_last_error(runtime, "Out of memory registering JavaScript module");
        return -1;
    }
    entry->next = runtime->modules;
    runtime->modules = entry;
    return 0;
}

FFI_PLUGIN_EXPORT void JSF_RuntimeClearModules(JSFRuntime *runtime)
{
    jsf_free_modules(runtime);
    jsf_free_module_aliases(runtime);
}

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeRegisterModuleAlias(JSFRuntime *runtime, const char *module_name, const char *resolved_name)
{
    if (!runtime || !module_name || !resolved_name)
        return -1;

    JSFModuleAliasEntry *entry = jsf_find_module_alias(runtime, module_name);
    if (entry)
    {
        char *copy = jsf_strdup(resolved_name);
        if (!copy)
        {
            jsf_set_last_error(runtime, "Out of memory registering JavaScript module alias");
            return -1;
        }
        free(entry->resolved_name);
        entry->resolved_name = copy;
        return 0;
    }

    entry = (JSFModuleAliasEntry *)calloc(1, sizeof(JSFModuleAliasEntry));
    if (!entry)
    {
        jsf_set_last_error(runtime, "Out of memory registering JavaScript module alias");
        return -1;
    }
    entry->name = jsf_strdup(module_name);
    entry->resolved_name = jsf_strdup(resolved_name);
    if (!entry->name || !entry->resolved_name)
    {
        free(entry->name);
        free(entry->resolved_name);
        free(entry);
        jsf_set_last_error(runtime, "Out of memory registering JavaScript module alias");
        return -1;
    }
    entry->next = runtime->module_aliases;
    runtime->module_aliases = entry;
    return 0;
}

FFI_PLUGIN_EXPORT int32_t JSF_RuntimeResolveDartFuture(JSFRuntime *runtime, int32_t future_id, const char *result_json, int32_t is_error)
{
    if (!runtime || !runtime->context)
        return -1;

    JSFDartFutureEntry *entry = jsf_take_dart_future(runtime, future_id);
    if (!entry)
    {
        jsf_set_last_error(runtime, "Dart Future resolver was not found");
        return -1;
    }

    JSValue value = jsf_parse_transfer_json(runtime, result_json);
    if (JS_IsException(value))
    {
        JS_FreeValue(runtime->context, entry->resolving_funcs[0]);
        JS_FreeValue(runtime->context, entry->resolving_funcs[1]);
        free(entry);
        return -1;
    }

    JSValue callback = entry->resolving_funcs[is_error ? 1 : 0];
    JSValue ret = JS_Call(runtime->context, callback, JS_UNDEFINED, 1, (JSValueConst *)&value);
    JS_FreeValue(runtime->context, value);
    JS_FreeValue(runtime->context, ret);
    JS_FreeValue(runtime->context, entry->resolving_funcs[0]);
    JS_FreeValue(runtime->context, entry->resolving_funcs[1]);
    free(entry);
    return JSF_RuntimeExecutePendingJobs(runtime);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_Eval(JSFRuntime *runtime, const char *code, const char *filename, int32_t module)
{
    if (!runtime || !runtime->context || !code)
        return NULL;

    int flags = module ? JS_EVAL_TYPE_MODULE : JS_EVAL_TYPE_GLOBAL;
    JSValue result = JS_Eval(runtime->context, code, strlen(code), filename ? filename : "<eval>", flags);
    if (JS_IsException(result))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    return jsf_value_new_owned(runtime, result);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_LoadModule(JSFRuntime *runtime, const char *module_name, const char *module_source)
{
    if (!runtime || !runtime->context)
        return NULL;
    JSModuleDef *module = JS_LoadMjsModule(runtime->context, module_name, module_source);
    if (!module)
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    JSValue namespace_value = JS_GetModuleNamespace(runtime->context, module);
    if (JS_IsException(namespace_value))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    return jsf_value_new_owned(runtime, namespace_value);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_GetGlobal(JSFRuntime *runtime, const char *name)
{
    if (!runtime || !runtime->context || !name)
        return NULL;
    JSValue global = JS_GetGlobalObject(runtime->context);
    JSValue value = JS_GetPropertyStr(runtime->context, global, name);
    JS_FreeValue(runtime->context, global);
    if (JS_IsException(value))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    return jsf_value_new_owned(runtime, value);
}

FFI_PLUGIN_EXPORT int32_t JSF_SetGlobal(JSFRuntime *runtime, const char *name, JSFValue *value)
{
    if (!runtime || !runtime->context || !name || !value)
        return -1;
    JSValue global = JS_GetGlobalObject(runtime->context);
    int ret = JS_SetPropertyStr(runtime->context, global, name, JS_DupValue(runtime->context, value->value));
    JS_FreeValue(runtime->context, global);
    if (ret < 0)
        jsf_capture_exception(runtime);
    return ret;
}

FFI_PLUGIN_EXPORT JSFValue *JSF_Call(JSFRuntime *runtime, JSFValue *function, JSFValue *this_value, JSFValue **argv, int32_t argc)
{
    if (!runtime || !runtime->context || !function)
        return NULL;

    JSValue *args = NULL;
    if (argc > 0)
    {
        args = (JSValue *)calloc((size_t)argc, sizeof(JSValue));
        if (!args)
        {
            jsf_set_last_error(runtime, "Out of memory allocating call arguments");
            return NULL;
        }
        for (int32_t i = 0; i < argc; i++)
            args[i] = argv && argv[i] ? JS_DupValue(runtime->context, argv[i]->value) : JS_UNDEFINED;
    }

    JSValue this_js = this_value ? this_value->value : JS_UNDEFINED;
    JSValue result = JS_Call(runtime->context, function->value, this_js, argc, args);
    if (args)
    {
        for (int32_t i = 0; i < argc; i++)
            JS_FreeValue(runtime->context, args[i]);
        free(args);
    }

    if (JS_IsException(result))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    return jsf_value_new_owned(runtime, result);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_CallGlobal(JSFRuntime *runtime, const char *name, JSFValue **argv, int32_t argc)
{
    JSFValue *function = JSF_GetGlobal(runtime, name);
    if (!function)
        return NULL;
    JSFValue *result = JSF_Call(runtime, function, NULL, argv, argc);
    JSF_ValueFree(function);
    return result;
}

FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartFunction(JSFRuntime *runtime, const char *name, JSFDartFunction callback, JSFDartFreeFunction free_result, void *opaque)
{
    if (!runtime || !runtime->context || !name || !callback)
        return -1;

    JSFDartCallbackEntry *entry = (JSFDartCallbackEntry *)calloc(1, sizeof(JSFDartCallbackEntry));
    if (!entry)
    {
        jsf_set_last_error(runtime, "Out of memory allocating Dart callback");
        return -1;
    }
    entry->id = runtime->next_callback_id++;
    entry->callback = callback;
    entry->free_result = free_result;
    entry->opaque = opaque;
    entry->next = runtime->callbacks;
    runtime->callbacks = entry;

    JSValue data[1] = {JS_NewInt32(runtime->context, entry->id)};
    JSValue function = JS_NewCFunctionData(runtime->context, jsf_dart_callback, 0, 0, 1, data);
    JS_FreeValue(runtime->context, data[0]);

    if (JS_IsException(function))
    {
        jsf_capture_exception(runtime);
        runtime->callbacks = entry->next;
        free(entry);
        return -1;
    }

    JSValue global = JS_GetGlobalObject(runtime->context);
    int ret = JS_SetPropertyStr(runtime->context, global, name, function);
    JS_FreeValue(runtime->context, global);
    if (ret < 0)
    {
        jsf_capture_exception(runtime);
        runtime->callbacks = entry->next;
        free(entry);
    }
    return ret;
}

FFI_PLUGIN_EXPORT int32_t JSF_RegisterDartHandleFunction(JSFRuntime *runtime, const char *name, JSFDartHandleFunction callback, void *opaque)
{
    if (!runtime || !runtime->context || !name || !callback)
        return -1;

    JSFDartCallbackEntry *entry = (JSFDartCallbackEntry *)calloc(1, sizeof(JSFDartCallbackEntry));
    if (!entry)
    {
        jsf_set_last_error(runtime, "Out of memory allocating Dart handle callback");
        return -1;
    }
    entry->id = runtime->next_callback_id++;
    entry->handle_callback = callback;
    entry->opaque = opaque;
    entry->next = runtime->callbacks;
    runtime->callbacks = entry;

    JSValue data[1] = {JS_NewInt32(runtime->context, entry->id)};
    JSValue function = JS_NewCFunctionData(runtime->context, jsf_dart_callback, 0, 0, 1, data);
    JS_FreeValue(runtime->context, data[0]);

    if (JS_IsException(function))
    {
        jsf_capture_exception(runtime);
        runtime->callbacks = entry->next;
        free(entry);
        return -1;
    }

    JSValue global = JS_GetGlobalObject(runtime->context);
    int ret = JS_SetPropertyStr(runtime->context, global, name, function);
    JS_FreeValue(runtime->context, global);
    if (ret < 0)
    {
        jsf_capture_exception(runtime);
        runtime->callbacks = entry->next;
        free(entry);
    }
    return ret;
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewUndefined(JSFRuntime *runtime)
{
    return jsf_value_new_owned(runtime, JS_UNDEFINED);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewNull(JSFRuntime *runtime)
{
    return jsf_value_new_owned(runtime, JS_NULL);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewBool(JSFRuntime *runtime, int32_t value)
{
    return jsf_value_new_owned(runtime, JS_NewBool(runtime->context, value));
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewInt64(JSFRuntime *runtime, int64_t value)
{
    return jsf_value_new_owned(runtime, JS_NewInt64(runtime->context, value));
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewFloat64(JSFRuntime *runtime, double value)
{
    return jsf_value_new_owned(runtime, JS_NewFloat64(runtime->context, value));
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewString(JSFRuntime *runtime, const char *value)
{
    return jsf_value_new_owned(runtime, JS_NewString(runtime->context, value ? value : ""));
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewBigInt(JSFRuntime *runtime, const char *decimal_value)
{
    if (!runtime || !runtime->context)
        return NULL;
    JSValue global = JS_GetGlobalObject(runtime->context);
    JSValue bigint = JS_GetPropertyStr(runtime->context, global, "BigInt");
    JSValue arg = JS_NewString(runtime->context, decimal_value ? decimal_value : "0");
    JSValue result = JS_Call(runtime->context, bigint, JS_UNDEFINED, 1, &arg);
    JS_FreeValue(runtime->context, arg);
    JS_FreeValue(runtime->context, bigint);
    JS_FreeValue(runtime->context, global);
    if (JS_IsException(result))
    {
        jsf_capture_exception(runtime);
        return NULL;
    }
    return jsf_value_new_owned(runtime, result);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewJson(JSFRuntime *runtime, const char *json)
{
    if (!runtime || !runtime->context)
        return NULL;
    JSValue value = jsf_parse_json(runtime, json);
    if (JS_IsException(value))
        return NULL;
    return jsf_value_new_owned(runtime, value);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewTransferJson(JSFRuntime *runtime, const char *json)
{
    if (!runtime || !runtime->context)
        return NULL;
    JSValue value = jsf_parse_transfer_json(runtime, json);
    if (JS_IsException(value))
        return NULL;
    return jsf_value_new_owned(runtime, value);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewArray(JSFRuntime *runtime)
{
    return jsf_value_new_owned(runtime, JS_NewArray(runtime->context));
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueNewObject(JSFRuntime *runtime)
{
    return jsf_value_new_owned(runtime, JS_NewObject(runtime->context));
}

FFI_PLUGIN_EXPORT void JSF_ValueFree(JSFValue *value)
{
    if (!value)
        return;
    if (value->owner && value->owner->context)
        JS_FreeValue(value->owner->context, value->value);
    free(value);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueDup(JSFValue *value)
{
    if (!value || !value->owner || !value->owner->context)
        return NULL;
    return jsf_value_new_owned(value->owner, JS_DupValue(value->owner->context, value->value));
}

FFI_PLUGIN_EXPORT JSFValueType JSF_ValueType(JSFValue *value)
{
    if (!value || !value->owner)
        return JSF_VALUE_UNKNOWN;

    JSContext *ctx = value->owner->context;
    if (JS_IsException(value->value))
        return JSF_VALUE_EXCEPTION;
    if (JS_IsUndefined(value->value))
        return JSF_VALUE_UNDEFINED;
    if (JS_IsNull(value->value))
        return JSF_VALUE_NULL;
    if (JS_IsBool(value->value))
        return JSF_VALUE_BOOL;
    if (JS_IsBigInt(ctx, value->value))
        return JSF_VALUE_BIGINT;
    if (JS_IsString(value->value))
        return JSF_VALUE_STRING;
    if (JS_IsNumber(value->value))
        return JS_VALUE_GET_TAG(value->value) == JS_TAG_INT ? JSF_VALUE_INT : JSF_VALUE_FLOAT;
    if (JS_IsObject(value->value))
    {
        if (JS_IsFunction(ctx, value->value))
            return JSF_VALUE_FUNCTION;
        if (JS_IsArray(ctx, value->value))
            return JSF_VALUE_ARRAY;
        if (JS_PromiseState(ctx, value->value) >= 0)
            return JSF_VALUE_PROMISE;
        return JSF_VALUE_OBJECT;
    }
    return JSF_VALUE_UNKNOWN;
}

FFI_PLUGIN_EXPORT int32_t JSF_ValueToBool(JSFValue *value)
{
    if (!value || !value->owner)
        return 0;
    return JS_ToBool(value->owner->context, value->value);
}

FFI_PLUGIN_EXPORT int64_t JSF_ValueToInt64(JSFValue *value)
{
    if (!value || !value->owner)
        return 0;
    int64_t out = 0;
    JS_ToInt64(value->owner->context, &out, value->value);
    return out;
}

FFI_PLUGIN_EXPORT double JSF_ValueToFloat64(JSFValue *value)
{
    if (!value || !value->owner)
        return 0.0;
    double out = 0;
    JS_ToFloat64(value->owner->context, &out, value->value);
    return out;
}

FFI_PLUGIN_EXPORT char *JSF_ValueToCString(JSFValue *value)
{
    if (!value || !value->owner)
        return NULL;
    return jsf_to_owned_cstring(value->owner->context, value->value);
}

FFI_PLUGIN_EXPORT char *JSF_ValueToJson(JSFValue *value)
{
    if (!value || !value->owner)
        return NULL;
    return jsf_value_to_json_owned(value->owner, value->value);
}

FFI_PLUGIN_EXPORT int32_t JSF_ValueArrayLength(JSFValue *value)
{
    if (!value || !value->owner)
        return -1;
    JSValue length = JS_GetPropertyStr(value->owner->context, value->value, "length");
    int32_t out = -1;
    JS_ToInt32(value->owner->context, &out, length);
    JS_FreeValue(value->owner->context, length);
    return out;
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueArrayGet(JSFValue *value, uint32_t index)
{
    if (!value || !value->owner)
        return NULL;
    JSValue element = JS_GetPropertyUint32(value->owner->context, value->value, index);
    if (JS_IsException(element))
    {
        jsf_capture_exception(value->owner);
        return NULL;
    }
    return jsf_value_new_owned(value->owner, element);
}

FFI_PLUGIN_EXPORT int32_t JSF_ValueArraySet(JSFValue *value, uint32_t index, JSFValue *element)
{
    if (!value || !value->owner || !element)
        return -1;
    int ret = JS_SetPropertyUint32(value->owner->context, value->value, index, JS_DupValue(value->owner->context, element->value));
    if (ret < 0)
        jsf_capture_exception(value->owner);
    return ret;
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValueObjectGet(JSFValue *value, const char *key)
{
    if (!value || !value->owner || !key)
        return NULL;
    JSValue property = JS_GetPropertyStr(value->owner->context, value->value, key);
    if (JS_IsException(property))
    {
        jsf_capture_exception(value->owner);
        return NULL;
    }
    return jsf_value_new_owned(value->owner, property);
}

FFI_PLUGIN_EXPORT int32_t JSF_ValueObjectSet(JSFValue *value, const char *key, JSFValue *property)
{
    if (!value || !value->owner || !key || !property)
        return -1;
    int ret = JS_SetPropertyStr(value->owner->context, value->value, key, JS_DupValue(value->owner->context, property->value));
    if (ret < 0)
        jsf_capture_exception(value->owner);
    return ret;
}

FFI_PLUGIN_EXPORT int32_t JSF_ValuePromiseState(JSFValue *value)
{
    if (!value || !value->owner || !value->owner->context)
        return -1;
    JSFValueType type = JSF_ValueType(value);
    if (type != JSF_VALUE_PROMISE)
        return -1;
    return (int32_t)JS_PromiseState(value->owner->context, value->value);
}

FFI_PLUGIN_EXPORT JSFValue *JSF_ValuePromiseResult(JSFValue *value)
{
    if (!value || !value->owner || !value->owner->context)
        return NULL;
    JSFValueType type = JSF_ValueType(value);
    if (type != JSF_VALUE_PROMISE)
        return NULL;
    JSValue result = JS_PromiseResult(value->owner->context, value->value);
    if (JS_IsException(result))
    {
        jsf_capture_exception(value->owner);
        return NULL;
    }
    return jsf_value_new_owned(value->owner, result);
}

FFI_PLUGIN_EXPORT void JSF_FreeCString(char *value)
{
    free(value);
}
