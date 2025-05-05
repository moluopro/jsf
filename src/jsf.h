/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// FFI_PLUGIN_EXPORT void qjs_init();
// FFI_PLUGIN_EXPORT const char* qjs_eval(const char* code);
// FFI_PLUGIN_EXPORT void qjs_free_result(const char* str);
// FFI_PLUGIN_EXPORT void qjs_cleanup();
// FFI_PLUGIN_EXPORT void qjs_exec_init_script(const char* code);
