/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

#include "jsf.h"

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
