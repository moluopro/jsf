import 'dart:convert';
import 'dart:js_interop';

import 'conversion.dart';

/// Browser-backed handle to a JavaScript value.
///
/// The web implementation mirrors the native [JsValue] API where browser
/// platform limits allow it.
class JsValue {
  /// Wraps a browser JavaScript value.
  JsValue(this._value, {bool owned = true}) : _owned = owned;

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

  /// Promise state placeholder for API parity with native platforms.
  int get promiseState => 0;

  /// Converts this JavaScript value to a Dart snapshot.
  dynamic toDart() {
    final encoded = _jsfTransferEncode(nativeValue);
    return decodeJsTransferValue(encoded.dartify());
  }

  /// Converts this value to JSF's transfer JSON schema.
  String toJson() {
    return jsonEncode(encodeJsTransferValue(toDart()));
  }

  /// Creates another handle to the same browser JavaScript value.
  JsValue duplicate() => JsValue(nativeValue);

  /// Returns this handle for API parity with native Promise handling.
  JsValue promiseResult() => this;

  /// Reads an object property by string [key].
  JsValue getPropertyValue(String key) {
    return JsValue(_jsfGetProperty(nativeValue, key.toJS));
  }

  /// Sets an object property by string [key].
  void setPropertyValue(String key, JsValue value) {
    _jsfSetProperty(nativeValue, key.toJS, value.nativeValue);
  }

  /// Reads an array-like item by [index].
  JsValue getIndexValue(int index) {
    return JsValue(_jsfGetIndex(nativeValue, index.toJS));
  }

  /// Sets an array-like item by [index].
  void setIndexValue(int index, JsValue value) {
    _jsfSetIndex(nativeValue, index.toJS, value.nativeValue);
  }

  /// Calls this value as a JavaScript function.
  JsValue callWithValues(List<JsValue> arguments, {JsValue? thisValue}) {
    final args = arguments.map((value) => value.nativeValue).toList().toJS;
    return JsValue(_jsfCall(nativeValue, thisValue?.nativeValue, args));
  }

  /// Disposes this browser-side handle wrapper.
  void dispose() {
    _value = null;
    _disposed = true;
  }

  void _ensureAlive() {
    if (_disposed) {
      throw StateError('JavaScript value has been disposed.');
    }
  }
}

/// Converts a Dart value to a browser JavaScript value through JSF's transfer
/// schema.
JSAny? webValueFromDart(Object? value) {
  ensureJsWebHelpers();
  final json = jsonEncode(encodeJsTransferValue(value));
  return _jsfTransferRevive(_jsonParse(json.toJS));
}

/// Converts a browser JavaScript value to a Dart snapshot.
Object? webValueToDart(JSAny? value) {
  ensureJsWebHelpers();
  return decodeJsTransferValue(_jsfTransferEncode(value).dartify());
}

/// Installs JSF's browser helper functions once per page.
void ensureJsWebHelpers() {
  if (_helpersInstalled) {
    return;
  }
  _jsEval(_helperSource.toJS);
  _helpersInstalled = true;
}

bool _helpersInstalled = false;

const _helperSource = r'''
(function(){
if(globalThis.__jsfTransferEncode)return;
globalThis.__jsfTransferEncode=function(v){
  const seen=[];
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
    if(seen.indexOf(x)>=0)throw new TypeError('circular reference');
    seen.push(x);
    try{
      if(x instanceof Date)return {'$jsf.type':'Date','value':x.toISOString()};
      if(x instanceof RegExp)return {'$jsf.type':'RegExp','source':x.source,'flags':x.flags};
      if(x instanceof Error)return {'$jsf.type':'Error','name':x.name,'message':x.message,'stack':x.stack};
      if(x instanceof Map)return {'$jsf.type':'Map','entries':Array.from(x.entries(),e=>[enc(e[0]),enc(e[1])])};
      if(x instanceof Set)return {'$jsf.type':'Set','values':Array.from(x.values(),enc)};
      if(typeof ArrayBuffer!=='undefined'&&ArrayBuffer.isView(x))return {'$jsf.type':'TypedArray','name':x.constructor.name,'values':Array.from(x)};
      if(typeof ArrayBuffer!=='undefined'&&x instanceof ArrayBuffer)return {'$jsf.type':'ArrayBuffer','bytes':Array.from(new Uint8Array(x))};
      if(Array.isArray(x)){const a=[];for(let i=0;i<x.length;i++)a.push(Object.prototype.hasOwnProperty.call(x,i)?enc(x[i]):{'$jsf.type':'ArrayHole'});return a;}
      const out={};Object.keys(x).forEach(k=>out[k]=enc(x[k]));return out;
    }finally{seen.pop();}
  }
  return enc(v);
};
globalThis.__jsfTransferRevive=function(v){
  function r(x){
    if(Array.isArray(x)){const a=[];for(let i=0;i<x.length;i++){const item=x[i];if(item&&item['$jsf.type']==='ArrayHole')a.length=i+1;else a[i]=r(item);}return a;}
    if(!x||typeof x!=='object')return x;
    const t=x['$jsf.type'];
    if(t==='Undefined')return undefined;
    if(t==='BigInt')return BigInt(x.value);
    if(t==='Number'){if(x.value==='NaN')return NaN;if(x.value==='Infinity')return Infinity;if(x.value==='-Infinity')return -Infinity;if(x.value==='-0')return -0;return Number(x.value);}
    if(t==='Date')return new Date(x.value);
    if(t==='RegExp')return new RegExp(x.source||'',x.flags||'');
    if(t==='Error'){const e=new Error(x.message||'');e.name=x.name||'Error';if(x.stack)e.stack=x.stack;return e;}
    if(t==='Map')return new Map((x.entries||[]).map(e=>[r(e[0]),r(e[1])]));
    if(t==='Set')return new Set((x.values||[]).map(r));
    if(t==='ArrayBuffer')return new Uint8Array(x.bytes||[]).buffer;
    if(t==='TypedArray'){const C=globalThis[x.name]||Array;try{return new C(x.values||[]);}catch(_){return x.values||[];}}
    const out={};Object.keys(x).forEach(k=>{if(k!=='$jsf.type')out[k]=r(x[k]);});return out;
  }
  return r(v);
};
globalThis.__jsfGetProperty=(o,k)=>o==null?undefined:o[k];
globalThis.__jsfSetProperty=(o,k,v)=>{ if(o!=null)o[k]=v; };
globalThis.__jsfGetIndex=(o,i)=>o==null?undefined:o[i];
globalThis.__jsfSetIndex=(o,i,v)=>{ if(o!=null)o[i]=v; };
globalThis.__jsfCall=(f,t,args)=>typeof f==='function'?f.apply(t,args||[]):undefined;
globalThis.__jsfValueType=function(v){
  if(v===undefined)return 0;
  if(v===null)return 1;
  if(typeof v==='boolean')return 2;
  if(typeof v==='number')return Number.isInteger(v)?3:4;
  if(typeof v==='bigint')return 5;
  if(typeof v==='string')return 6;
  if(Array.isArray(v))return 7;
  if(typeof v==='function')return 9;
  if(v&&typeof v.then==='function')return 10;
  if(typeof v==='object')return 8;
  return 100;
};
globalThis.__jsfValueLength=function(v){ return v&&typeof v.length==='number'?v.length:0; };
const moduleRegistries=new Map();
function moduleRegistry(id){
  id=String(id);
  let r=moduleRegistries.get(id);
  if(!r){
    r={modules:new Map(),aliases:new Map(),cache:new Map(),nativeUrls:new Map()};
    moduleRegistries.set(id,r);
  }
  return r;
}
function revokeNativeUrls(r){
  r.nativeUrls.forEach(function(url){
    try{URL.revokeObjectURL(url);}catch(_){}
  });
  r.nativeUrls.clear();
}
function normalizePath(name){
  const out=[];
  String(name).split('/').forEach(function(part){
    if(!part||part==='.')return;
    if(part==='..')out.pop();
    else out.push(part);
  });
  return out.join('/');
}
function dirname(name){
  name=String(name||'');
  const index=name.lastIndexOf('/');
  return index<0?'':name.slice(0,index);
}
function resolveModule(r,specifier,referrer){
  let spec=String(specifier);
  if(r.aliases.has(spec))spec=r.aliases.get(spec);
  if(spec.startsWith('.')){
    const base=dirname(referrer);
    spec=base?base+'/'+spec:spec;
  }
  return normalizePath(spec);
}
function splitTopLevel(text){
  const parts=[];
  let start=0,depth=0,quote='',escape=false;
  for(let i=0;i<text.length;i++){
    const c=text[i];
    if(quote){
      if(escape){escape=false;continue;}
      if(c==='\\'){escape=true;continue;}
      if(c===quote)quote='';
      continue;
    }
    if(c==='"'||c==="'"||c==='`'){quote=c;continue;}
    if(c==='('||c==='['||c==='{')depth++;
    else if(c===')'||c===']'||c==='}')depth--;
    else if(c===','&&depth===0){
      parts.push(text.slice(start,i).trim());
      start=i+1;
    }
  }
  const tail=text.slice(start).trim();
  if(tail)parts.push(tail);
  return parts;
}
function declarationNames(declarations){
  return splitTopLevel(declarations).map(function(part){
    const m=part.match(/^\s*([A-Za-z_$][\w$]*)/);
    return m?m[1]:null;
  }).filter(Boolean);
}
function namedImportPattern(names){
  return names.split(',').map(function(part){
    part=part.trim();
    if(!part)return '';
    const m=part.match(/^([A-Za-z_$][\w$]*)\s+as\s+([A-Za-z_$][\w$]*)$/);
    return m?m[1]+': '+m[2]:part;
  }).filter(Boolean).join(', ');
}
function importStatement(bindings,specifier){
  bindings=bindings.trim();
  const spec=JSON.stringify(specifier);
  if(!bindings)return '__import('+spec+');';
  if(bindings.startsWith('{')){
    return 'const {'+namedImportPattern(bindings.slice(1,-1))+'}=__import('+spec+');';
  }
  if(bindings.startsWith('*')){
    const m=bindings.match(/^\*\s+as\s+([A-Za-z_$][\w$]*)$/);
    if(!m)throw new SyntaxError('Unsupported namespace import: '+bindings);
    return 'const '+m[1]+'=__import('+spec+');';
  }
  const comma=bindings.indexOf(',');
  if(comma>=0){
    const first=bindings.slice(0,comma).trim();
    const rest=bindings.slice(comma+1).trim();
    return 'const '+first+'=__import('+spec+').default;'+importStatement(rest,specifier);
  }
  return 'const '+bindings+'=__import('+spec+').default;';
}
function rewriteDynamicImports(source,runtimeId,referrer,moduleMode){
  return String(source).replace(/\bimport\s*\(\s*(['"])([^'"]+)\1\s*\)/g,function(_,q,spec){
    if(moduleMode)return '__importAsync('+JSON.stringify(spec)+')';
    return 'globalThis.__jsfModuleImport('+JSON.stringify(runtimeId)+','+JSON.stringify(spec)+','+JSON.stringify(referrer||'<eval>')+')';
  });
}
function nativeModuleUrl(runtimeId,specifier,referrer){
  const r=moduleRegistry(runtimeId);
  const name=resolveModule(r,specifier,referrer||'');
  if(r.nativeUrls.has(name))return r.nativeUrls.get(name);
  if(!r.modules.has(name))throw new Error('JSF module not found: '+name);
  const source=rewriteNativeModuleSpecifiers(r.modules.get(name),runtimeId,name);
  const blob=new Blob([source+'\n//# sourceURL=jsf-module://'+name],{type:'text/javascript'});
  const url=URL.createObjectURL(blob);
  r.nativeUrls.set(name,url);
  return url;
}
function nativeEvalUrl(runtimeId,source,filename){
  const rewritten=rewriteNativeModuleSpecifiers(source,runtimeId,String(filename||'<eval>'));
  const blob=new Blob([rewritten+'\n//# sourceURL=jsf-module-eval://'+String(filename||'<eval>')],{type:'text/javascript'});
  return URL.createObjectURL(blob);
}
function rewriteNativeModuleSpecifiers(source,runtimeId,referrer){
  source=String(source);
  source=source.replace(/(\bfrom\s*)(['"])([^'"]+)\2/g,function(_,prefix,quote,spec){
    return prefix+quote+nativeModuleUrl(runtimeId,spec,referrer)+quote;
  });
  source=source.replace(/(\bimport\s*)(['"])([^'"]+)\2/g,function(_,prefix,quote,spec){
    return prefix+quote+nativeModuleUrl(runtimeId,spec,referrer)+quote;
  });
  source=source.replace(/\bimport\s*\(\s*(['"])([^'"]+)\1\s*\)/g,function(_,quote,spec){
    return 'import('+JSON.stringify(nativeModuleUrl(runtimeId,spec,referrer))+')';
  });
  return source;
}
function transpileModule(source,runtimeId,referrer){
  const exportNames=[];
  source=rewriteDynamicImports(source,runtimeId,referrer,true);
  source=source.replace(/\bimport\s+([\s\S]*?)\s+from\s*(['"])([^'"]+)\2\s*;?/g,function(_,bindings,_q,spec){
    return importStatement(bindings,spec);
  });
  source=source.replace(/\bimport\s*(['"])([^'"]+)\1\s*;?/g,function(_,q,spec){
    return '__import('+JSON.stringify(spec)+');';
  });
  source=source.replace(/\bexport\s+default\s+function\s+([A-Za-z_$][\w$]*)\s*\(/g,function(_,name){
    exportNames.push({local:name,exported:'default'});
    return 'function '+name+'(';
  });
  source=source.replace(/\bexport\s+default\s+class\s+([A-Za-z_$][\w$]*)/g,function(_,name){
    exportNames.push({local:name,exported:'default'});
    return 'class '+name;
  });
  source=source.replace(/\bexport\s+default\s+([^;]+);/g,function(_,expr){
    return '__exports.default=('+expr+');';
  });
  source=source.replace(/\bexport\s+(async\s+function|function|class)\s+([A-Za-z_$][\w$]*)/g,function(_,kind,name){
    exportNames.push({local:name,exported:name});
    return kind+' '+name;
  });
  source=source.replace(/\bexport\s+(const|let|var)\s+([^;]+);/g,function(_,kind,decls){
    declarationNames(decls).forEach(function(name){
      exportNames.push({local:name,exported:name});
    });
    return kind+' '+decls+';';
  });
  source=source.replace(/\bexport\s+\*\s+from\s*(['"])([^'"]+)\1\s*;?/g,function(_,q,spec){
    return '(()=>{const m=__import('+JSON.stringify(spec)+');Object.keys(m).forEach(function(k){if(k!=="default")__exports[k]=m[k];});})();';
  });
  source=source.replace(/\bexport\s*\{([^}]+)\}\s+from\s*(['"])([^'"]+)\2\s*;?/g,function(_,list,q,spec){
    return splitTopLevel(list).map(function(part){
      const m=part.match(/^([A-Za-z_$][\w$]*|default)(?:\s+as\s+([A-Za-z_$][\w$]*|default))?$/);
      if(!m)throw new SyntaxError('Unsupported re-export: '+part);
      return '__exports['+JSON.stringify(m[2]||m[1])+']=__import('+JSON.stringify(spec)+')['+JSON.stringify(m[1])+'];';
    }).join('');
  });
  source=source.replace(/\bexport\s*\{([^}]+)\}\s*;?/g,function(_,list){
    return splitTopLevel(list).map(function(part){
      const m=part.match(/^([A-Za-z_$][\w$]*)(?:\s+as\s+([A-Za-z_$][\w$]*|default))?$/);
      if(!m)throw new SyntaxError('Unsupported export: '+part);
      return '__exports['+JSON.stringify(m[2]||m[1])+']='+m[1]+';';
    }).join('');
  });
  const footer=exportNames.map(function(item){
    return '__exports['+JSON.stringify(item.exported)+']='+item.local+';';
  }).join('');
  return source+'\n;'+footer;
}
function requireModule(runtimeId,specifier,referrer){
  const r=moduleRegistry(runtimeId);
  const name=resolveModule(r,specifier,referrer||'');
  if(r.cache.has(name))return r.cache.get(name).exports;
  if(!r.modules.has(name))throw new Error('JSF module not found: '+name);
  const record={exports:{}};
  r.cache.set(name,record);
  const code=transpileModule(r.modules.get(name),runtimeId,name);
  const importer=function(spec){return requireModule(runtimeId,spec,name);};
  const importerAsync=function(spec){return Promise.resolve(requireModule(runtimeId,spec,name));};
  try{
    Function('__exports','__import','__importAsync','globalThis',code)(record.exports,importer,importerAsync,globalThis);
  }catch(error){
    r.cache.delete(name);
    throw error;
  }
  return record.exports;
}
globalThis.__jsfEval=function(runtimeId,code,filename){
  return (0,eval)(rewriteDynamicImports(code,runtimeId,filename||'<eval>',false));
};
globalThis.__jsfModuleEval=function(runtimeId,code,filename){
  const exports={};
  const referrer=String(filename||'<eval>');
  const moduleCode=transpileModule(code,runtimeId,referrer);
  const importer=function(spec){return requireModule(runtimeId,spec,referrer);};
  const importerAsync=function(spec){return Promise.resolve(requireModule(runtimeId,spec,referrer));};
  Function('__exports','__import','__importAsync','globalThis',moduleCode)(exports,importer,importerAsync,globalThis);
  return exports;
};
globalThis.__jsfModuleImport=function(runtimeId,specifier,referrer){
  return import(nativeModuleUrl(runtimeId,specifier,referrer||'<eval>'));
};
globalThis.__jsfModuleEvalAsync=function(runtimeId,code,filename){
  const url=nativeEvalUrl(runtimeId,code,filename);
  return import(url).finally(function(){try{URL.revokeObjectURL(url);}catch(_){}});
};
globalThis.__jsfModuleLoad=function(runtimeId,moduleName){
  return requireModule(runtimeId,moduleName,'');
};
globalThis.__jsfModuleRegister=function(runtimeId,moduleName,moduleSource){
  const r=moduleRegistry(runtimeId);
  const name=resolveModule(r,moduleName,'');
  r.modules.set(name,String(moduleSource));
  r.cache.clear();
  revokeNativeUrls(r);
};
globalThis.__jsfModuleAlias=function(runtimeId,moduleName,resolvedName){
  const r=moduleRegistry(runtimeId);
  r.aliases.set(String(moduleName),String(resolvedName));
  r.cache.clear();
  revokeNativeUrls(r);
};
globalThis.__jsfModuleClear=function(runtimeId){
  const r=moduleRegistry(runtimeId);
  r.modules.clear();
  r.aliases.clear();
  r.cache.clear();
  revokeNativeUrls(r);
};
globalThis.__jsfModuleDispose=function(runtimeId){
  const r=moduleRegistries.get(String(runtimeId));
  if(r)revokeNativeUrls(r);
  moduleRegistries.delete(String(runtimeId));
};
})();
''';

@JS('eval')
external JSAny? _jsEval(JSString code);

@JS('JSON.parse')
external JSAny? _jsonParse(JSString text);

@JS('__jsfTransferEncode')
external JSAny _jsfTransferEncode(JSAny? value);

@JS('__jsfTransferRevive')
external JSAny? _jsfTransferRevive(JSAny? value);

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
