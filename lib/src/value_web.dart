import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'conversion.dart';
import 'exception.dart';
import 'web_compiler_js.dart';
import 'web_module_js.dart';

/// Browser-backed handle to a JavaScript value.
///
/// The web implementation mirrors the native [JsValue] API where browser
/// platform limits allow it.
class WebValueOwner {
  bool disposed = false;
  JSObject? realm;
  int _nextHandle = 1;
  final Map<int, WeakReference<JsValue>> _values = {};
  int get liveHandles {
    _values.removeWhere((_, value) => value.target == null);
    return _values.length;
  }

  void dispose() {
    for (final weak in _values.values.toList()) {
      weak.target?.dispose();
    }
    _values.clear();
    realm = null;
    disposed = true;
  }
}

class JsValue {
  /// Wraps a browser JavaScript value.
  JsValue(this._value, {bool owned = true, this.owner}) : _owned = owned {
    _jsfTrackPromise(_value, owner?.realm);
    if (_owned && owner != null) {
      _id = owner!._nextHandle++;
      owner!._values[_id!] = WeakReference(this);
    }
  }

  final WebValueOwner? owner;
  int? _id;

  JSAny? _value;
  final bool _owned;
  bool _disposed = false;

  /// Raw JavaScript value used internally by JS interop.
  JSAny? get nativeValue {
    _ensureAlive();
    return _value;
  }

  /// Whether this handle has been disposed.
  bool get isDisposed => _disposed;

  /// Whether this handle owns the wrapped value reference.
  bool get isOwned => _owned;

  /// JSF-compatible value type tag.
  int get type => _jsfValueType(nativeValue).toDartInt;

  /// Array-like length, or `0` for non-array values.
  int get length => _jsfValueLength(nativeValue).toDartInt;

  /// Promise state: 0 pending, 1 fulfilled, 2 rejected.
  int get promiseState =>
      webInterop(() => _jsfPromiseState(nativeValue)).toDartInt;

  /// Converts this JavaScript value to a Dart snapshot.
  dynamic toDart() {
    if (type == 11) return toBytes();
    final encoded = webInterop(() => _jsfTransferEncode(nativeValue));
    return decodeJsTransferValue(encoded.dartify());
  }

  /// Copies an ArrayBuffer into Dart bytes.
  Uint8List toBytes() {
    if (type != 11) {
      throw JsException('Expected an ArrayBuffer.', name: 'TypeError');
    }
    return _jsfCopyBuffer(nativeValue).toDart;
  }

  /// Converts this value to JSF's transfer JSON schema.
  String toJson() {
    return jsonEncode(encodeJsTransferValue(toDart()));
  }

  /// Creates another handle to the same browser JavaScript value.
  JsValue duplicate() => JsValue(nativeValue, owner: owner);

  /// Returns a new handle to the settlement value, or undefined while pending.
  JsValue promiseResult() =>
      JsValue(webInterop(() => _jsfPromiseResult(nativeValue)), owner: owner);

  /// Reads an object property by string [key].
  JsValue getPropertyValue(String key) {
    final raw = nativeValue;
    return JsValue(webInterop(() => _jsfGetProperty(raw, key.toJS)),
        owner: owner);
  }

  /// Sets an object property by string [key].
  void setPropertyValue(String key, JsValue value) {
    checkOwner(value);
    final raw = nativeValue, property = value.nativeValue;
    webInterop(() => _jsfSetProperty(raw, key.toJS, property));
  }

  /// Reads an array-like item by [index].
  JsValue getIndexValue(int index) {
    RangeError.checkValueInInterval(index, 0, 4294967294, 'index');
    final raw = nativeValue;
    return JsValue(webInterop(() => _jsfGetIndex(raw, index.toJS)),
        owner: owner);
  }

  /// Sets an array-like item by [index].
  void setIndexValue(int index, JsValue value) {
    checkOwner(value);
    RangeError.checkValueInInterval(index, 0, 4294967294, 'index');
    final raw = nativeValue, element = value.nativeValue;
    webInterop(() => _jsfSetIndex(raw, index.toJS, element));
  }

  /// Calls this value as a JavaScript function.
  JsValue callWithValues(List<JsValue> arguments, {JsValue? thisValue}) {
    for (final value in arguments) {
      checkOwner(value);
    }
    if (thisValue != null) checkOwner(thisValue);
    final args = arguments.map((value) => value.nativeValue).toList().toJS;
    final raw = nativeValue, thisRaw = thisValue?.nativeValue;
    return JsValue(webInterop(() => _jsfCall(raw, thisRaw, args)),
        owner: owner);
  }

  /// Disposes this browser-side handle wrapper.
  void dispose() {
    if (_id != null) owner?._values.remove(_id);
    _value = null;
    _disposed = true;
  }

  void checkOwner(JsValue value) {
    _ensureAlive();
    value._ensureAlive();
    if (!identical(owner, value.owner)) {
      throw ArgumentError('JavaScript value belongs to a different runtime.');
    }
  }

  void _ensureAlive() {
    if (owner?.disposed == true) {
      throw StateError('JavaScript runtime has been disposed.');
    }
    if (_disposed) {
      throw StateError('JavaScript value has been disposed.');
    }
  }
}

/// Converts a Dart value to a browser JavaScript value through JSF's transfer
/// schema.
JSAny? webValueFromDart(Object? value, [JSObject? realm]) {
  ensureJsWebHelpers();
  if (value is Uint8List) return _jsfBufferFromBytes(value.toJS, realm);
  final json = jsonEncode(encodeJsTransferValue(value));
  return webInterop(() => _jsfTransferRevive(_jsonParse(json.toJS), realm));
}

/// Converts a browser JavaScript value to a Dart snapshot.
Object? webValueToDart(JSAny? value) {
  ensureJsWebHelpers();
  return decodeJsTransferValue(_jsfTransferEncode(value).dartify());
}

/// Installs JSF's browser helper functions once per page.
void ensureJsWebHelpers({bool modules = false}) {
  if (!_helpersInstalled) {
    _jsEval(_helperSource.toJS);
    _jsEval(webModuleRuntime.toJS);
    _helpersInstalled = true;
  }
  if (modules && !_compilerInstalled) {
    _jsEval(webModuleCompiler.toJS);
    _compilerInstalled = true;
  }
}

bool _compilerInstalled = false;

bool _helpersInstalled = false;

const _helperSource = r'''
(function(){
if(globalThis.__jsfTransferEncode)return;
globalThis.__jsfTransferEncode=function(v){
  const seen=new Set();
  function enc(x){
    if(x===undefined)return {'$jsf.type':'Undefined'};
    if(typeof x==='bigint')return {'$jsf.type':'BigInt','value':x.toString()};
    if(typeof x==='number'){
      if(Number.isNaN(x))return {'$jsf.type':'Number','value':'NaN'};
      if(x===Infinity)return {'$jsf.type':'Number','value':'Infinity'};
      if(x===-Infinity)return {'$jsf.type':'Number','value':'-Infinity'};
      if(Object.is(x,-0))return {'$jsf.type':'Number','value':'-0'};
      return x;
    }
    if(typeof x==='function')return {'$jsf.type':'Function'};
    if(typeof x==='symbol')return {'$jsf.type':'Symbol','value':String(x)};
    if(x===null||typeof x!=='object')return x;
    if(seen.has(x))throw new TypeError('circular reference');
    seen.add(x);
    try{
      if(Object.prototype.toString.call(x)==='[object Date]')return {'$jsf.type':'Date','value':x.toISOString()};
      if(Object.prototype.toString.call(x)==='[object RegExp]')return {'$jsf.type':'RegExp','source':x.source,'flags':x.flags};
      if(/Error\]$/.test(Object.prototype.toString.call(x)))return {'$jsf.type':'Error','name':x.name,'message':x.message,'stack':x.stack};
      if(Object.prototype.toString.call(x)==='[object Map]')return {'$jsf.type':'Map','entries':Array.from(x.entries(),e=>[enc(e[0]),enc(e[1])])};
      if(Object.prototype.toString.call(x)==='[object Set]')return {'$jsf.type':'Set','values':Array.from(x.values(),enc)};
      if(Object.prototype.toString.call(x)==='[object DataView]')return {'$jsf.type':'DataView','bytes':Array.from(new Uint8Array(x.buffer,x.byteOffset,x.byteLength))};
      if(ArrayBuffer.isView(x))return {'$jsf.type':'TypedArray','name':x.constructor.name,'values':Array.from(x,enc)};
      if(Object.prototype.toString.call(x)==='[object ArrayBuffer]')return {'$jsf.type':'ArrayBuffer','bytes':Array.from(new Uint8Array(x))};
      if(Array.isArray(x)){const a=[];for(let i=0;i<x.length;i++)a.push(Object.prototype.hasOwnProperty.call(x,i)?enc(x[i]):{'$jsf.type':'ArrayHole'});return a;}
      const out=Object.create(null);Object.keys(x).forEach(k=>out[k]=enc(x[k]));return Object.hasOwn(x,'$jsf.type')?{'$jsf.type':'Object',entries:Object.entries(out)}:out;
    }finally{seen.delete(x);}
  }
  return enc(v);
};
globalThis.__jsfTransferRevive=function(v,realm){
  const g=realm||globalThis;
  function r(x){
    if(Array.isArray(x)){const a=new g.Array();for(let i=0;i<x.length;i++){const item=x[i];if(item&&item['$jsf.type']==='ArrayHole')a.length=i+1;else a[i]=r(item);}return a;}
    if(!x||typeof x!=='object')return x;
    const t=x['$jsf.type'];
    if(t==='Undefined')return undefined;
    if(t==='BigInt')return BigInt(x.value);
    if(t==='Number'){if(x.value==='NaN')return NaN;if(x.value==='Infinity')return Infinity;if(x.value==='-Infinity')return -Infinity;if(x.value==='-0')return -0;return Number(x.value);}
    if(t==='Date')return new g.Date(x.value);
    if(t==='RegExp')return new g.RegExp(x.source||'',x.flags||'');
    if(t==='Error'){const e=new g.Error(x.message||'');e.name=x.name||'Error';if(x.stack)e.stack=x.stack;return e;}
    if(t==='Map')return new g.Map((x.entries||[]).map(e=>[r(e[0]),r(e[1])]));
    if(t==='Set')return new g.Set((x.values||[]).map(r));
    if(t==='ArrayBuffer')return new g.Uint8Array(x.bytes||[]).buffer;
    if(t==='DataView')return new g.DataView(new g.Uint8Array(x.bytes||[]).buffer);
    if(t==='TypedArray'){const C=g[x.name];if(typeof C!=='function'||!C.BYTES_PER_ELEMENT)throw new TypeError('Unknown typed array');return new C((x.values||[]).map(r));}
    const out=new g.Object();const entries=t==='Object'?x.entries:Object.entries(x);for(const [key,value] of entries)Object.defineProperty(out,key,{value:r(value),writable:true,enumerable:true,configurable:true});return out;
  }
  return r(v);
};
globalThis.__jsfCopyBuffer=value=>new Uint8Array(new Uint8Array(value));
globalThis.__jsfBufferFromBytes=(bytes,realm)=>new (realm||globalThis).Uint8Array(bytes).buffer;
globalThis.__jsfUnwrapFuture=promise=>promise.then(result=>{if(result.error)throw result.value;return result.value;});
globalThis.__jsfGetProperty=(o,k)=>o==null?undefined:o[k];
globalThis.__jsfSetProperty=(o,k,v)=>{ if(o!=null)o[k]=v; };
globalThis.__jsfGetIndex=(o,i)=>o==null?undefined:o[i];
globalThis.__jsfSetIndex=(o,i,v)=>{ if(o!=null)o[i]=v; };
globalThis.__jsfCall=(f,t,args)=>{if(typeof f!=='function')throw new TypeError('Value is not callable');return Reflect.apply(f,t,args||[]);};
const promises=new WeakMap();
globalThis.__jsfTrackPromise=function(value,realm){
  if(!value||typeof value.then!=='function'||promises.has(value))return;
  const state={state:0,value:undefined,observed:false};promises.set(value,state);
  const promise=Promise.resolve(value);
  promise.then(result=>{state.state=1;state.value=result;},error=>{state.state=2;state.value=error;
    if(realm)setTimeout(()=>{if(!state.observed&&!realm.__jsfDisposed)realm.dispatchEvent(new realm.PromiseRejectionEvent('unhandledrejection',{promise,reason:error}));},0);
  });
};
globalThis.__jsfObservePromise=function(value){const state=promises.get(value);if(state)state.observed=true;};
globalThis.__jsfPromiseState=function(value){const state=promises.get(value);if(!state)throw new TypeError('Expected a Promise');return state.state;};
globalThis.__jsfPromiseResult=function(value){const state=promises.get(value);if(!state)throw new TypeError('Expected a Promise');return state.value;};
globalThis.__jsfCallback=function(invoke,realm){const bridge={invoke(args){if(!invoke)throw new realm.Error('Dart callback is not registered');const result=invoke(args);if(result.error)throw result.value;return result.value;},dispose(){invoke=null;}};bridge.function=realm.Function('bridge','return function(...args){return bridge.invoke(args)}')(bridge);return bridge;};
globalThis.__jsfValueType=function(v){
  if(v===undefined)return 0;
  if(v===null)return 1;
  if(typeof v==='boolean')return 2;
  if(typeof v==='number')return Number.isInteger(v)?3:4;
  if(typeof v==='bigint')return 5;
  if(typeof v==='string')return 6;
  if(Object.prototype.toString.call(v)==='[object ArrayBuffer]')return 11;
  if(Array.isArray(v))return 7;
  if(typeof v==='function')return 9;
  if(v&&typeof v.then==='function')return 10;
  if(typeof v==='object')return 8;
  return 100;
};
globalThis.__jsfValueLength=function(v){ return v&&typeof v.length==='number'?v.length:0; };
})();
''';

@JS('eval')
external JSAny? _jsEval(JSString code);

@JS('JSON.parse')
external JSAny? _jsonParse(JSString text);

@JS('__jsfTransferEncode')
external JSAny _jsfTransferEncode(JSAny? value);

@JS('__jsfTransferRevive')
external JSAny? _jsfTransferRevive(JSAny? value, JSObject? realm);

@JS('__jsfGetProperty')
external JSAny? _jsfGetProperty(JSAny? object, JSString key);

@JS('__jsfSetProperty')
external void _jsfSetProperty(JSAny? object, JSString key, JSAny? value);

@JS('__jsfGetIndex')
external JSAny? _jsfGetIndex(JSAny? object, JSNumber index);

@JS('__jsfSetIndex')
external void _jsfSetIndex(JSAny? object, JSNumber index, JSAny? value);

@JS('__jsfCall')
external JSAny? _jsfCall(
    JSAny? function, JSAny? thisValue, JSArray<JSAny?> args);

@JS('__jsfValueType')
external JSNumber _jsfValueType(JSAny? value);

@JS('__jsfValueLength')
external JSNumber _jsfValueLength(JSAny? value);

@JS('__jsfTrackPromise')
external void _jsfTrackPromise(JSAny? value, JSObject? realm);
@JS('__jsfPromiseState')
external JSNumber _jsfPromiseState(JSAny? value);
@JS('__jsfPromiseResult')
external JSAny? _jsfPromiseResult(JSAny? value);

T webInterop<T>(T Function() operation) {
  try {
    return operation();
  } catch (error) {
    throw webException(error);
  }
}

JsException webException(Object error) {
  if (error is JsException) return error;
  try {
    final object = error as JSObject;
    return JsException((object['message']?.dartify() ?? error).toString(),
        name: (object['name']?.dartify() ?? 'Error').toString(),
        stack: object['stack']?.dartify()?.toString(),
        cause: object['cause']?.dartify());
  } catch (_) {
    return JsException(error.toString());
  }
}

@JS('__jsfObservePromise')
external void webObservePromise(JSAny? value);

@JS('__jsfCopyBuffer')
external JSUint8Array _jsfCopyBuffer(JSAny? value);
@JS('__jsfBufferFromBytes')
external JSAny? _jsfBufferFromBytes(JSUint8Array bytes, JSObject? realm);
