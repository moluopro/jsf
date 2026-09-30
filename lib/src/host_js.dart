const nativeHostBootstrap = r'''
(function(schedule,cancel,report,log){
'use strict';
const token={},signals=new WeakMap();
function error(name,message){const e=new Error(message);e.name=name;return e;}
globalThis.setTimeout=function(fn,delay=0,...args){if(typeof fn!=='function')throw new TypeError('Timer callback must be a function');return schedule(fn,Math.min(2147483647,Math.max(0,Number(delay)||0)),false,args);};
globalThis.setInterval=function(fn,delay=0,...args){if(typeof fn!=='function')throw new TypeError('Timer callback must be a function');return schedule(fn,Math.min(2147483647,Math.max(1,Number(delay)||1)),true,args);};
globalThis.clearTimeout=globalThis.clearInterval=function(id){cancel(Number(id));};
globalThis.queueMicrotask=function(fn){if(typeof fn!=='function')throw new TypeError('Microtask callback must be a function');Promise.resolve().then(fn).catch(report);};
  class AbortSignal {
    constructor(secret) {
      if (secret !== token) throw new TypeError("Illegal constructor");
      signals.set(this, {
        aborted: false,
        reason: undefined,
        listeners: [],
        onabort: null,
      });
    }
    get aborted() {
      return signals.get(this).aborted;
    }
    get reason() {
      return signals.get(this).reason;
    }
    get onabort() {
      return signals.get(this).onabort;
    }
    set onabort(fn) {
      signals.get(this).onabort = fn;
    }
    throwIfAborted() {
      if (this.aborted) throw this.reason;
    }
    addEventListener(type, fn, options) {
      if (type !== "abort" || !fn) return;
      const list = signals.get(this).listeners;
      if (!list.some((x) => x.fn === fn))
        list.push({ fn, once: !!(options && options.once) });
    }
    removeEventListener(type, fn) {
      if (type === "abort")
        signals.get(this).listeners = signals
          .get(this)
          .listeners.filter((x) => x.fn !== fn);
    }
    static timeout(milliseconds) {
      const delay = Number(milliseconds);
      if (!Number.isSafeInteger(delay) || delay < 0 || delay > 2147483647) throw new RangeError('Invalid abort timeout');
      const controller = new AbortController();
      setTimeout(() => controller.abort(error('TimeoutError','The operation timed out.')), delay);
      return controller.signal;
    }
    static any(iterable) {
      const list=Array.from(iterable);
      for(const signal of list)if(!signals.has(signal))throw new TypeError('Expected AbortSignal');
      const controller=new AbortController(), cleanups=[];
      const finish=signal=>{controller.abort(signal.reason);for(const cleanup of cleanups)cleanup();cleanups.length=0;};
      for(const signal of list) {
        if(signal.aborted){finish(signal);break;}
        const listener=()=>finish(signal);
        signal.addEventListener('abort',listener,{once:true});
        cleanups.push(()=>signal.removeEventListener('abort',listener));
      }
      return controller.signal;
    }
    static abort(reason) {
      const c = new AbortController();
      c.abort(reason);
      return c.signal;
    }
  }
  class AbortController {
    constructor() {
      Object.defineProperty(this, "signal", {
        value: new AbortSignal(token),
        enumerable: true,
      });
    }
    abort(reason) {
      const state = signals.get(this.signal);
      if (state.aborted) return;
      state.aborted = true;
      state.reason =
        reason === undefined
          ? error("AbortError", "The request was aborted.")
          : reason;
      const event = { type: "abort", target: this.signal };
      for (const listener of state.listeners.slice()) {
        if (listener.once)
          this.signal.removeEventListener("abort", listener.fn);
        try {
          if (typeof listener.fn === "function")
            listener.fn.call(this.signal, event);
          else listener.fn.handleEvent(event);
        } catch (_) {}
      }
      if (typeof state.onabort === "function") {
        try {
          state.onabort.call(this.signal, event);
        } catch (_) {}
      }
    }
  }
Object.assign(globalThis,{AbortSignal,AbortController});
if(log)globalThis.console=Object.fromEntries(['log','info','debug','warn','error'].map(level=>[level,(...args)=>log(level,args)]));
})
''';
