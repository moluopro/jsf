#include "jsf.h"
#ifdef NDEBUG
#undef NDEBUG
#endif
#include <assert.h>

static void expect_json(JSFValue *value, const char *expected)
{
    assert(value);
    char *json = JSF_ValueToJson(value);
    assert(json && strcmp(json, expected) == 0);
    JSF_FreeCString(json);
    JSF_ValueFree(value);
}

static JSFValue *active_handle;
static char *free_active_handle(void *opaque, const char *args)
{
    (void)opaque; (void)args;
    JSF_ValueFree(active_handle); active_handle = NULL;
    return NULL;
}
static char *try_free_runtime(void *opaque, const char *args)
{
    (void)args;
    JSF_RuntimeFree(opaque);
    assert(strstr(JSF_RuntimeLastError(opaque), "Cannot dispose"));
    return NULL;
}
static char *register_during_setter(void *opaque, const char *args)
{
    (void)args;
    assert(JSF_RegisterDartFunction(opaque, "nestedRegistered", try_free_runtime, NULL, opaque) >= 0);
    return NULL;
}

static void check_runtime_safety(void)
{
    JSFRuntime *a=JSF_RuntimeNew(), *b=JSF_RuntimeNew();
    assert(a && b && JSF_ABIVersion()==2 && strlen(JSF_EngineVersion())>0);
    JSFValue *object=JSF_Eval(a,"({x:42})","owner",0);
    JSFValue *receiver=JSF_Eval(b,"({})","receiver",0);
    JSFValue *function=JSF_Eval(b,"(x)=>x","function",0);
    assert(JSF_SetGlobal(b,"foreign",object)<0);
    assert(JSF_SetGlobalJson(b,"\"foreign\"",object)<0);
    assert(JSF_ValueArraySet(receiver,0,object)<0);
    assert(JSF_ValueObjectSetJson(receiver,"\"x\"",object)<0);
    assert(!JSF_Call(b,function,NULL,&object,1));
    assert(!JSF_Call(b,function,object,NULL,0));
    assert(!JSF_Call(b,object,NULL,NULL,0));
    assert(!JSF_Call(b,function,NULL,NULL,-1));
    JSF_RuntimeFree(a); /* Refuse freeing outstanding handles, without aborting. */
    assert(strstr(JSF_RuntimeLastError(a),"handles"));
    JSF_ValueFree(object);JSF_ValueFree(receiver);JSF_ValueFree(function);
    JSF_RegisterDartFunction(a,"tryClose",try_free_runtime,NULL,a);
    expect_json(JSF_Eval(a,"tryClose();42","reentrant",0),"42");
    JSF_RegisterDartFunction(a,"freeHandle",free_active_handle,NULL,NULL);
    active_handle=JSF_Eval(a,"({get x(){freeHandle();return 42}})","getter",0);
    expect_json(JSF_ValueObjectGet(active_handle,"x"),"42");
    assert(!active_handle);
    active_handle=JSF_Eval(a,"(()=>{freeHandle();return 42})","call",0);
    expect_json(JSF_Call(a,active_handle,NULL,NULL,0),"42");
    assert(!active_handle);
    JSF_RegisterDartFunction(a,"registerNested",register_during_setter,NULL,a);
    expect_json(JSF_Eval(a,"Object.defineProperty(globalThis,'rejectRegistration',{set(value){registerNested();throw new Error('setter failed')}});42","setter",0),"42");
    assert(JSF_RegisterDartFunction(a,"rejectRegistration",try_free_runtime,NULL,a)<0);
    expect_json(JSF_Eval(a,"nestedRegistered();42","registration recovery",0),"42");
    JSF_RuntimeSetTimeout(a,1);
    assert(!JSF_Eval(a,"while(true){}","timeout",0));
    expect_json(JSF_Eval(a,"42","recovery",0),"42");
    JSF_RuntimeClearTimeout(a);
    JSF_RuntimeFree(a);JSF_RuntimeFree(b);
}

int main(void)
{
    for (int iteration = 0; iteration < 100; iteration++)
    {
        check_runtime_safety();
        JSFRuntime *runtime = JSF_RuntimeNew();
        assert(runtime);
        const char code[] = "\"a\0b\"";
        expect_json(JSF_EvalLen(runtime, code, sizeof(code) - 1, "unicode", 0), "\"a\\u0000b\"");
        expect_json(JSF_Eval(runtime, "'\\ud800'", "surrogate", 0), "\"\\ud800\"");
        JSFValue *object = JSF_Eval(runtime, "({'a':1,'a\\u0000b':2})", "keys", 0);
        expect_json(JSF_ValueObjectGetJson(object, "\"a\\u0000b\""), "2");
        JSF_ValueFree(object);
        const uint8_t bytes[] = {0, 128, 255};
        JSFValue *buffer = JSF_ValueNewArrayBuffer(runtime, bytes, sizeof(bytes));
        size_t length = 0;
        const uint8_t *data = JSF_ValueArrayBufferData(buffer, &length);
        assert(data && length == sizeof(bytes) && memcmp(data, bytes, length) == 0);
        JSF_ValueFree(buffer);

        uint8_t *writable = (uint8_t *)(uintptr_t)1;
        assert(!JSF_ValueAllocArrayBuffer(NULL, 0, &writable) && !writable);
        assert(!JSF_ValueAllocArrayBuffer(runtime, 0, NULL));
        buffer = JSF_ValueAllocArrayBuffer(runtime, 0, &writable);
        assert(buffer && writable);
        data = JSF_ValueArrayBufferData(buffer, &length);
        assert(data && length == 0);
        JSF_ValueFree(buffer);

        buffer = JSF_ValueAllocArrayBuffer(runtime, 65536, &writable);
        assert(buffer && writable);
        for (size_t i = 0; i < 65536; i++)
        {
            assert(writable[i] == 0);
            writable[i] = (uint8_t)i;
        }
        assert(JSF_SetGlobal(runtime, "allocated", buffer) >= 0);
        JSF_ValueFree(buffer); /* JS retains storage after the C handle is freed. */
        expect_json(JSF_Eval(runtime,
            "(()=>{const a=new Uint8Array(allocated);return a.length===65536&&a.every((x,i)=>x===(i&255))})()",
            "allocated", 0), "true");
        expect_json(JSF_Eval(runtime,
            "(()=>{const b=allocated.transfer();const c=b.transfer(65539);const a=new Uint8Array(c);"
            "return allocated.byteLength===0&&b.byteLength===0&&a[255]===255&&a[65535]===255&&a[65536]===0&&a[65538]===0})()",
            "transfer", 0), "true");
        writable = (uint8_t *)(uintptr_t)1;
        assert(!JSF_ValueAllocArrayBuffer(runtime, SIZE_MAX, &writable) && !writable);

        /* Exercise backing-store OOM and recovery under the QuickJS quota. */
        JSF_RuntimeSetMemoryLimit(runtime, 1024 * 1024);
        for (int failure = 0; failure < 3; failure++)
        {
            writable = (uint8_t *)(uintptr_t)1;
            assert(!JSF_ValueAllocArrayBuffer(runtime, 4 * 1024 * 1024, &writable));
            assert(!writable);
        }
        JSF_RuntimeSetMemoryLimit(runtime, SIZE_MAX);
        buffer = JSF_ValueAllocArrayBuffer(runtime, sizeof(bytes), &writable);
        assert(buffer && writable);
        memcpy(writable, bytes, sizeof(bytes));
        JSF_ValueFree(buffer);
        assert(!JSF_Eval(runtime, "throw new Error('a\\u0000b\\ud800')", "error", 0));
        const char *error = JSF_RuntimeLastErrorJson(runtime);
        assert(error && strstr(error, "a\\u0000b\\ud800"));
        JSF_RuntimeFree(runtime);
    }
    puts("Native ABI Unicode, writable buffers, quotas and lifecycle checks passed.");
    return 0;
}
