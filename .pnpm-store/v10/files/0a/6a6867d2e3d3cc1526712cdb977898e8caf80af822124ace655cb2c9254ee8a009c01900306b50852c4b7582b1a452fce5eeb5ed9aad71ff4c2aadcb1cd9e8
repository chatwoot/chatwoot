var FormKitVue = (function (exports, Vue) {
  'use strict';

  var __defProp = Object.defineProperty;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __esm = (fn, res) => function __init() {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };

  // packages/utils/dist/index.mjs
  function token() {
    return Math.random().toString(36).substring(2, 15);
  }
  function dedupe(arr1, arr2) {
    const original = arr1 instanceof Set ? arr1 : new Set(arr1);
    if (arr2)
      arr2.forEach((item) => original.add(item));
    return [...original];
  }
  function has(obj, property) {
    return Object.prototype.hasOwnProperty.call(obj, property);
  }
  function eq(valA, valB, deep = true, explicit = ["__key"]) {
    if (valA === valB)
      return true;
    if (typeof valB === "object" && typeof valA === "object") {
      if (valA instanceof Map)
        return false;
      if (valA instanceof Set)
        return false;
      if (valA instanceof Date && valB instanceof Date)
        return valA.getTime() === valB.getTime();
      if (valA instanceof RegExp && valB instanceof RegExp)
        return eqRegExp(valA, valB);
      if (valA === null || valB === null)
        return false;
      if (Object.keys(valA).length !== Object.keys(valB).length)
        return false;
      for (const k of explicit) {
        if ((k in valA || k in valB) && valA[k] !== valB[k])
          return false;
      }
      for (const key in valA) {
        if (!(key in valB))
          return false;
        if (valA[key] !== valB[key] && !deep)
          return false;
        if (deep && !eq(valA[key], valB[key], deep, explicit))
          return false;
      }
      return true;
    }
    return false;
  }
  function eqRegExp(x, y) {
    return x.source === y.source && x.flags.split("").sort().join("") === y.flags.split("").sort().join("");
  }
  function empty(value) {
    const type = typeof value;
    if (type === "number")
      return false;
    if (value === void 0)
      return true;
    if (type === "string") {
      return value === "";
    }
    if (type === "object") {
      if (value === null)
        return true;
      for (const _i in value)
        return false;
      if (value instanceof RegExp)
        return false;
      if (value instanceof Date)
        return false;
      return true;
    }
    return false;
  }
  function escapeExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }
  function regexForFormat(format) {
    const escaped = `^${escapeExp(format)}$`;
    const formats = {
      MM: "(0[1-9]|1[012])",
      M: "([1-9]|1[012])",
      DD: "([012][0-9]|3[01])",
      D: "([012]?[0-9]|3[01])",
      YYYY: "\\d{4}",
      YY: "\\d{2}"
    };
    const tokens = Object.keys(formats);
    return new RegExp(
      tokens.reduce((regex, format2) => {
        return regex.replace(format2, formats[format2]);
      }, escaped)
    );
  }
  function isRecord(o) {
    return Object.prototype.toString.call(o) === "[object Object]";
  }
  function isObject(o) {
    return isRecord(o) || Array.isArray(o);
  }
  function isPojo(o) {
    if (isRecord(o) === false)
      return false;
    if (o.__FKNode__ || o.__POJO__ === false)
      return false;
    const ctor = o.constructor;
    if (ctor === void 0)
      return true;
    const prot = ctor.prototype;
    if (isRecord(prot) === false)
      return false;
    if (prot.hasOwnProperty("isPrototypeOf") === false) {
      return false;
    }
    return true;
  }
  function isQuotedString(str) {
    if (str[0] !== '"' && str[0] !== "'")
      return false;
    if (str[0] !== str[str.length - 1])
      return false;
    const quoteType = str[0];
    for (let p = 1; p < str.length; p++) {
      if (str[p] === quoteType && (p === 1 || str[p - 1] !== "\\") && p !== str.length - 1) {
        return false;
      }
    }
    return true;
  }
  function rmEscapes(str) {
    if (!str.length)
      return "";
    let clean2 = "";
    let lastChar = "";
    for (let p = 0; p < str.length; p++) {
      const char = str.charAt(p);
      if (char !== "\\" || lastChar === "\\") {
        clean2 += char;
      }
      lastChar = char;
    }
    return clean2;
  }
  function nodeProps(...sets) {
    return sets.reduce((valid, props) => {
      const { value, name, modelValue, config, plugins, ...validProps } = props;
      return Object.assign(valid, validProps);
    }, {});
  }
  function parseArgs(str) {
    const args = [];
    let arg = "";
    let depth = 0;
    let quote = "";
    let lastChar = "";
    for (let p = 0; p < str.length; p++) {
      const char = str.charAt(p);
      if (char === quote && lastChar !== "\\") {
        quote = "";
      } else if ((char === "'" || char === '"') && !quote && lastChar !== "\\") {
        quote = char;
      } else if (char === "(" && !quote) {
        depth++;
      } else if (char === ")" && !quote) {
        depth--;
      }
      if (char === "," && !quote && depth === 0) {
        args.push(arg);
        arg = "";
      } else if (char !== " " || quote) {
        arg += char;
      }
      lastChar = char;
    }
    if (arg) {
      args.push(arg);
    }
    return args;
  }
  function except(obj, toRemove) {
    const clean2 = {};
    const exps = toRemove.filter((n) => n instanceof RegExp);
    const keysToRemove = new Set(toRemove);
    for (const key in obj) {
      if (!keysToRemove.has(key) && !exps.some((exp) => exp.test(key))) {
        clean2[key] = obj[key];
      }
    }
    return clean2;
  }
  function only(obj, include) {
    const clean2 = {};
    const exps = include.filter((n) => n instanceof RegExp);
    include.forEach((key) => {
      if (!(key instanceof RegExp)) {
        clean2[key] = obj[key];
      }
    });
    Object.keys(obj).forEach((key) => {
      if (exps.some((exp) => exp.test(key))) {
        clean2[key] = obj[key];
      }
    });
    return clean2;
  }
  function camel(str) {
    return str.replace(
      /-([a-z0-9])/gi,
      (_s, g) => g.toUpperCase()
    );
  }
  function kebab(str) {
    return str.replace(
      /([a-z0-9])([A-Z])/g,
      (_s, trail, cap) => trail + "-" + cap.toLowerCase()
    ).replace(" ", "-").toLowerCase();
  }
  function shallowClone(obj, explicit = explicitKeys) {
    if (obj !== null && typeof obj === "object") {
      let returnObject;
      if (Array.isArray(obj))
        returnObject = [...obj];
      else if (isPojo(obj))
        returnObject = { ...obj };
      if (returnObject) {
        applyExplicit(obj, returnObject, explicit);
        return returnObject;
      }
    }
    return obj;
  }
  function clone(obj, explicit = explicitKeys) {
    if (obj === null || obj instanceof RegExp || obj instanceof Date || obj instanceof Map || obj instanceof Set || typeof File === "function" && obj instanceof File)
      return obj;
    let returnObject;
    if (Array.isArray(obj)) {
      returnObject = obj.map((value) => {
        if (typeof value === "object")
          return clone(value, explicit);
        return value;
      });
    } else {
      returnObject = Object.keys(obj).reduce((newObj, key) => {
        newObj[key] = typeof obj[key] === "object" ? clone(obj[key], explicit) : obj[key];
        return newObj;
      }, {});
    }
    for (const key of explicit) {
      if (key in obj) {
        Object.defineProperty(returnObject, key, {
          enumerable: false,
          value: obj[key]
        });
      }
    }
    return returnObject;
  }
  function cloneAny(obj) {
    return typeof obj === "object" ? clone(obj) : obj;
  }
  function getAt(obj, addr) {
    if (!obj || typeof obj !== "object")
      return null;
    const segments = addr.split(".");
    let o = obj;
    for (const i in segments) {
      const segment = segments[i];
      if (has(o, segment)) {
        o = o[segment];
      }
      if (+i === segments.length - 1)
        return o;
      if (!o || typeof o !== "object")
        return null;
    }
    return null;
  }
  function undefine(value) {
    return value !== void 0 && value !== "false" && value !== false ? true : void 0;
  }
  function init(obj) {
    return !Object.isFrozen(obj) ? Object.defineProperty(obj, "__init", {
      enumerable: false,
      value: true
    }) : obj;
  }
  function slugify(str) {
    return str.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[^a-z0-9]/g, " ").trim().replace(/\s+/g, "-");
  }
  function applyExplicit(original, obj, explicit) {
    for (const key of explicit) {
      if (key in original) {
        Object.defineProperty(obj, key, {
          enumerable: false,
          value: original[key]
        });
      }
    }
    return obj;
  }
  function oncePerTick(fn) {
    let called = false;
    return (...args) => {
      if (called)
        return;
      called = true;
      queueMicrotask(() => called = false);
      return fn(...args);
    };
  }
  function boolGetter(value) {
    if (value === "false" || value === false)
      return void 0;
    return true;
  }
  var explicitKeys, extend;
  var init_dist = __esm({
    "packages/utils/dist/index.mjs"() {
      explicitKeys = [
        "__key",
        "__init",
        "__shim",
        "__original",
        "__index",
        "__prevKey"
      ];
      extend = /* @__NO_SIDE_EFFECTS__ */ (original, additional, extendArrays = false, ignoreUndefined = false) => {
        if (additional === null)
          return null;
        const merged = {};
        if (typeof additional === "string")
          return additional;
        for (const key in original) {
          if (has(additional, key) && (additional[key] !== void 0 || !ignoreUndefined)) {
            if (extendArrays && Array.isArray(original[key]) && Array.isArray(additional[key])) {
              merged[key] = original[key].concat(additional[key]);
              continue;
            }
            if (additional[key] === void 0) {
              continue;
            }
            if (isPojo(original[key]) && isPojo(additional[key])) {
              merged[key] = /* @__PURE__ */ extend(
                original[key],
                additional[key],
                extendArrays,
                ignoreUndefined
              );
            } else {
              merged[key] = additional[key];
            }
          } else {
            merged[key] = original[key];
          }
        }
        for (const key in additional) {
          if (!has(merged, key) && additional[key] !== void 0) {
            merged[key] = additional[key];
          }
        }
        return merged;
      };
    }
  });

  // packages/core/dist/index.mjs
  function createDispatcher() {
    const middleware = [];
    let currentIndex = 0;
    const use2 = (dispatchable) => middleware.push(dispatchable);
    const dispatch = (payload) => {
      const current = middleware[currentIndex];
      if (typeof current === "function") {
        return current(payload, (explicitPayload) => {
          currentIndex++;
          return dispatch(explicitPayload);
        });
      }
      currentIndex = 0;
      return payload;
    };
    use2.dispatch = dispatch;
    use2.unshift = (dispatchable) => middleware.unshift(dispatchable);
    use2.remove = (dispatchable) => {
      const index = middleware.indexOf(dispatchable);
      if (index > -1)
        middleware.splice(index, 1);
    };
    return use2;
  }
  function createEmitter() {
    const listeners = /* @__PURE__ */ new Map();
    const receipts2 = /* @__PURE__ */ new Map();
    let buffer = void 0;
    const emitter = (node, event) => {
      if (buffer) {
        buffer.set(event.name, [node, event]);
        return;
      }
      if (listeners.has(event.name)) {
        listeners.get(event.name).forEach((wrapper2) => {
          if (event.origin === node || wrapper2.modifiers.includes("deep")) {
            wrapper2.listener(event);
          }
        });
      }
      if (event.bubble) {
        node.bubble(event);
      }
    };
    emitter.flush = () => {
      listeners.clear();
      receipts2.clear();
      buffer?.clear();
    };
    emitter.on = (eventName, listener, pos = "push") => {
      const [event, ...modifiers] = eventName.split(".");
      const receipt = listener.receipt || token();
      const wrapper2 = {
        modifiers,
        event,
        listener,
        receipt
      };
      listeners.has(event) ? listeners.get(event)[pos](wrapper2) : listeners.set(event, [wrapper2]);
      receipts2.has(receipt) ? receipts2.get(receipt)[pos](event) : receipts2.set(receipt, [event]);
      return receipt;
    };
    emitter.off = (receipt) => {
      if (receipts2.has(receipt)) {
        receipts2.get(receipt)?.forEach((event) => {
          const eventListeners = listeners.get(event);
          if (Array.isArray(eventListeners)) {
            listeners.set(
              event,
              eventListeners.filter((wrapper2) => wrapper2.receipt !== receipt)
            );
          }
        });
        receipts2.delete(receipt);
      }
    };
    emitter.pause = (node) => {
      if (!buffer)
        buffer = /* @__PURE__ */ new Map();
      if (node) {
        node.walk((child) => child._e.pause());
      }
    };
    emitter.play = (node) => {
      if (!buffer)
        return;
      const events = buffer;
      buffer = void 0;
      events.forEach(([node2, event]) => emitter(node2, event));
      if (node) {
        node.walk((child) => child._e.play());
      }
    };
    return emitter;
  }
  function emit(node, context, name, payload, bubble2 = true, meta2) {
    context._e(node, {
      payload,
      name,
      bubble: bubble2,
      origin: node,
      meta: meta2
    });
    return node;
  }
  function bubble(node, _context, event) {
    if (isNode(node.parent)) {
      node.parent._e(node.parent, event);
    }
    return node;
  }
  function on(_node, context, name, listener, pos) {
    return context._e.on(name, listener, pos);
  }
  function off(node, context, receipt) {
    context._e.off(receipt);
    return node;
  }
  function warn(code, data = {}) {
    warningHandler.dispatch({ code, data });
  }
  function error(code, data = {}) {
    throw Error(exports.errorHandler.dispatch({ code, data }).message);
  }
  function createMessage(conf, node) {
    const m = {
      blocking: false,
      key: token(),
      meta: {},
      type: "state",
      visible: true,
      ...conf
    };
    if (node && m.value && m.meta.localize !== false) {
      m.value = node.t(m);
      m.meta.locale = node.config.locale;
    }
    return m;
  }
  function createStore(_buffer = false) {
    const messages4 = {};
    let node;
    let buffer = _buffer;
    let _b = [];
    const _m = /* @__PURE__ */ new Map();
    let _r = void 0;
    const store = new Proxy(messages4, {
      get(...args) {
        const [_target, property] = args;
        if (property === "buffer")
          return buffer;
        if (property === "_b")
          return _b;
        if (property === "_m")
          return _m;
        if (property === "_r")
          return _r;
        if (has(storeTraps, property)) {
          return storeTraps[property].bind(
            null,
            messages4,
            store,
            node
          );
        }
        return Reflect.get(...args);
      },
      set(_t, prop, value) {
        if (prop === "_n") {
          node = value;
          if (_r === "__n")
            releaseMissed(node, store);
          return true;
        } else if (prop === "_b") {
          _b = value;
          return true;
        } else if (prop === "buffer") {
          buffer = value;
          return true;
        } else if (prop === "_r") {
          _r = value;
          return true;
        }
        error(101, node);
        return false;
      }
    });
    return store;
  }
  function setMessage(messageStore, store, node, message4) {
    if (store.buffer) {
      store._b.push([[message4]]);
      return store;
    }
    if (messageStore[message4.key] !== message4) {
      if (typeof message4.value === "string" && message4.meta.localize !== false) {
        const previous = message4.value;
        message4.value = node.t(message4);
        if (message4.value !== previous) {
          message4.meta.locale = node.props.locale;
        }
      }
      const e = `message-${has(messageStore, message4.key) ? "updated" : "added"}`;
      messageStore[message4.key] = Object.freeze(
        node.hook.message.dispatch(message4)
      );
      node.emit(e, message4);
    }
    return store;
  }
  function touchMessages(messageStore, store) {
    for (const key in messageStore) {
      const message4 = { ...messageStore[key] };
      store.set(message4);
    }
  }
  function removeMessage(messageStore, store, node, key) {
    if (has(messageStore, key)) {
      const message4 = messageStore[key];
      delete messageStore[key];
      node.emit("message-removed", message4);
    }
    if (store.buffer === true) {
      store._b = store._b.filter((buffered) => {
        buffered[0] = buffered[0].filter((m) => m.key !== key);
        return buffered[1] || buffered[0].length;
      });
    }
    return store;
  }
  function filterMessages(messageStore, store, node, callback, type) {
    for (const key in messageStore) {
      const message4 = messageStore[key];
      if ((!type || message4.type === type) && !callback(message4)) {
        removeMessage(messageStore, store, node, key);
      }
    }
  }
  function reduceMessages(messageStore, _store, _node, reducer, accumulator) {
    for (const key in messageStore) {
      const message4 = messageStore[key];
      accumulator = reducer(accumulator, message4);
    }
    return accumulator;
  }
  function applyMessages(_messageStore, store, node, messages4, clear) {
    if (Array.isArray(messages4)) {
      if (store.buffer) {
        store._b.push([messages4, clear]);
        return;
      }
      const applied = new Set(
        messages4.map((message4) => {
          store.set(message4);
          return message4.key;
        })
      );
      if (typeof clear === "string") {
        store.filter(
          (message4) => message4.type !== clear || applied.has(message4.key)
        );
      } else if (typeof clear === "function") {
        store.filter((message4) => !clear(message4) || applied.has(message4.key));
      }
    } else {
      for (const address in messages4) {
        const child = node.at(address);
        if (child) {
          child.store.apply(messages4[address], clear);
        } else {
          missed(node, store, address, messages4[address], clear);
        }
      }
    }
  }
  function createMessages(node, ...errors2) {
    const sourceKey = `${node.name}-set`;
    const make = (error2) => /* @__PURE__ */ createMessage({
      key: slugify(error2),
      type: "error",
      value: error2,
      meta: { source: sourceKey, autoClear: true }
    });
    return errors2.filter((m) => !!m).map((errorSet) => {
      if (typeof errorSet === "string")
        errorSet = [errorSet];
      if (Array.isArray(errorSet)) {
        return errorSet.map((error2) => make(error2));
      } else {
        const errors22 = {};
        for (const key in errorSet) {
          if (Array.isArray(errorSet[key])) {
            errors22[key] = errorSet[key].map(
              (error2) => make(error2)
            );
          } else {
            errors22[key] = [make(errorSet[key])];
          }
        }
        return errors22;
      }
    });
  }
  function missed(node, store, address, messages4, clear) {
    const misses = store._m;
    if (!misses.has(address))
      misses.set(address, []);
    if (!store._r)
      store._r = releaseMissed(node, store);
    misses.get(address)?.push([messages4, clear]);
  }
  function releaseMissed(node, store) {
    return node.on(
      "child.deep",
      ({ payload: child }) => {
        store._m.forEach((misses, address) => {
          if (node.at(address) === child) {
            misses.forEach(([messages4, clear]) => {
              child.store.apply(messages4, clear);
            });
            store._m.delete(address);
          }
        });
        if (store._m.size === 0 && store._r) {
          node.off(store._r);
          store._r = void 0;
        }
      }
    );
  }
  function releaseBuffer(_messageStore, store) {
    store.buffer = false;
    store._b.forEach(([messages4, clear]) => store.apply(messages4, clear));
    store._b = [];
  }
  function createLedger() {
    const ledger = {};
    let n;
    return {
      count: (...args) => createCounter(n, ledger, ...args),
      init(node) {
        n = node;
        node.on("message-added.deep", add(ledger, 1));
        node.on("message-removed.deep", add(ledger, -1));
      },
      merge: (child) => merge(n, ledger, child),
      settled(counterName) {
        return has(ledger, counterName) ? ledger[counterName].promise : Promise.resolve();
      },
      unmerge: (child) => merge(n, ledger, child, true),
      value(counterName) {
        return has(ledger, counterName) ? ledger[counterName].count : 0;
      }
    };
  }
  function createCounter(node, ledger, counterName, condition, increment = 0) {
    condition = parseCondition(condition || counterName);
    if (!has(ledger, counterName)) {
      const counter = {
        condition,
        count: 0,
        name: counterName,
        node,
        promise: Promise.resolve(),
        resolve: () => {
        }
        // eslint-disable-line @typescript-eslint/no-empty-function
      };
      ledger[counterName] = counter;
      increment = node.store.reduce(
        (sum, m) => sum + counter.condition(m) * 1,
        increment
      );
      node.each((child) => {
        child.ledger.count(counter.name, counter.condition);
        increment += child.ledger.value(counter.name);
      });
    }
    return count(ledger[counterName], increment).promise;
  }
  function parseCondition(condition) {
    if (typeof condition === "function") {
      return condition;
    }
    return (m) => m.type === condition;
  }
  function count(counter, increment) {
    const initial = counter.count;
    const post = counter.count + increment;
    counter.count = post;
    if (initial === 0 && post !== 0) {
      counter.node.emit(`unsettled:${counter.name}`, counter.count, false);
      counter.promise = new Promise((r) => counter.resolve = r);
    } else if (initial !== 0 && post === 0) {
      counter.node.emit(`settled:${counter.name}`, counter.count, false);
      counter.resolve();
    }
    counter.node.emit(`count:${counter.name}`, counter.count, false);
    return counter;
  }
  function add(ledger, delta) {
    return (e) => {
      for (const name in ledger) {
        const counter = ledger[name];
        if (counter.condition(e.payload)) {
          count(counter, delta);
        }
      }
    };
  }
  function merge(parent, ledger, child, remove = false) {
    const originalParent = parent;
    for (const key in ledger) {
      const condition = ledger[key].condition;
      if (!remove)
        child.ledger.count(key, condition);
      const increment = child.ledger.value(key) * (remove ? -1 : 1);
      if (!parent)
        continue;
      do {
        parent.ledger.count(key, condition, increment);
        parent = parent.parent;
      } while (parent);
      parent = originalParent;
    }
  }
  function register(node) {
    if (node.props.id) {
      registry.set(node.props.id, node);
      reflected.set(node, node.props.id);
      emit2(node, {
        payload: node,
        name: node.props.id,
        bubble: false,
        origin: node
      });
    }
  }
  function deregister(node) {
    if (reflected.has(node)) {
      const id = reflected.get(node);
      reflected.delete(node);
      registry.delete(id);
      emit2(node, {
        payload: null,
        name: id,
        bubble: false,
        origin: node
      });
    }
  }
  function getNode(id) {
    return registry.get(id);
  }
  function watchRegistry(id, callback) {
    const receipt = emit2.on(id, callback);
    receipts.push(receipt);
    return receipt;
  }
  function stopWatch(receipt) {
    emit2.off(receipt);
  }
  function configChange(node, prop, value) {
    let usingFallback = true;
    !(prop in node.config._t) ? node.emit(`config:${prop}`, value, false) : usingFallback = false;
    if (!(prop in node.props)) {
      node.emit("prop", { prop, value });
      node.emit(`prop:${prop}`, value);
    }
    return usingFallback;
  }
  function createConfig(options2 = {}) {
    const nodes = /* @__PURE__ */ new Set();
    const target = {
      ...options2,
      ...{
        _add: (node) => nodes.add(node),
        _rm: (node) => nodes.delete(node)
      }
    };
    const rootConfig = new Proxy(target, {
      set(t, prop, value, r) {
        if (typeof prop === "string") {
          nodes.forEach((node) => configChange(node, prop, value));
        }
        return Reflect.set(t, prop, value, r);
      }
    });
    return rootConfig;
  }
  function submitForm(id, root) {
    const formElement = (root || document).getElementById(id);
    if (formElement instanceof HTMLFormElement) {
      const event = new Event("submit", { cancelable: true, bubbles: true });
      formElement.dispatchEvent(event);
      return;
    }
    warn(151, id);
  }
  function clearState(node) {
    const clear = (n) => {
      for (const key in n.store) {
        const message4 = n.store[key];
        if (message4.type === "error" || message4.type === "ui" && key === "incomplete") {
          n.store.remove(key);
        } else if (message4.type === "state") {
          n.store.set({ ...message4, value: false });
        }
      }
    };
    clear(node);
    node.walk(clear);
  }
  function reset(id, resetTo) {
    const node = typeof id === "string" ? getNode(id) : id;
    if (node) {
      const initial = (n) => cloneAny(n.props.initial) || (n.type === "group" ? {} : n.type === "list" ? [] : void 0);
      node._e.pause(node);
      const resetValue2 = cloneAny(resetTo);
      if (resetTo && !empty(resetTo)) {
        node.props.initial = isObject(resetValue2) ? init(resetValue2) : resetValue2;
        node.props._init = node.props.initial;
      }
      node.input(initial(node), false);
      node.walk((child) => {
        if (child.type === "list" && child.sync)
          return;
        child.input(initial(child), false);
      });
      node.input(
        empty(resetValue2) && resetValue2 ? resetValue2 : initial(node),
        false
      );
      const isDeepReset = node.type !== "input" && resetTo && !empty(resetTo) && isObject(resetTo);
      if (isDeepReset) {
        node.walk((child) => {
          child.props.initial = isObject(child.value) ? init(child.value) : child.value;
          child.props._init = child.props.initial;
        });
      }
      node._e.play(node);
      clearState(node);
      node.emit("reset", node);
      return node;
    }
    warn(152, id);
    return;
  }
  function isList(arg) {
    return arg.type === "list" && Array.isArray(arg._value);
  }
  function isNode(node) {
    return node && typeof node === "object" && node.__FKNode__ === true;
  }
  function createTraps() {
    return new Map(Object.entries(traps));
  }
  function trap(getter, setter, curryGetter = true) {
    return {
      get: getter ? (node, context) => curryGetter ? (...args) => getter(node, context, ...args) : getter(node, context) : false,
      set: setter !== void 0 ? setter : invalidSetter.bind(null)
    };
  }
  function createHooks() {
    const hooks = /* @__PURE__ */ new Map();
    return new Proxy(hooks, {
      get(_, property) {
        if (!hooks.has(property)) {
          hooks.set(property, createDispatcher());
        }
        return hooks.get(property);
      }
    });
  }
  function resetCount() {
    nameCount = 0;
    idCount = 0;
  }
  function createName(options2) {
    if (options2.parent?.type === "list")
      return useIndex;
    return options2.name || `${options2.props?.type || "input"}_${++nameCount}`;
  }
  function createValue(options2) {
    if (options2.type === "group") {
      return init(
        options2.value && typeof options2.value === "object" && !Array.isArray(options2.value) ? options2.value : {}
      );
    } else if (options2.type === "list") {
      return init(Array.isArray(options2.value) ? options2.value : []);
    }
    return options2.value;
  }
  function input(node, context, value, async = true) {
    context._value = validateInput(node, node.hook.input.dispatch(value));
    node.emit("input", context._value);
    if (node.isCreated && node.type === "input" && eq(context._value, context.value) && !node.props.mergeStrategy) {
      node.emit("commitRaw", context.value);
      return context.settled;
    }
    if (context.isSettled)
      node.disturb();
    if (async) {
      if (context._tmo)
        clearTimeout(context._tmo);
      context._tmo = setTimeout(
        commit,
        node.props.delay,
        node,
        context
      );
    } else {
      commit(node, context);
    }
    return context.settled;
  }
  function validateInput(node, value) {
    switch (node.type) {
      case "input":
        break;
      case "group":
        if (!value || typeof value !== "object")
          error(107, [node, value]);
        break;
      case "list":
        if (!Array.isArray(value))
          error(108, [node, value]);
        break;
    }
    return value;
  }
  function commit(node, context, calm2 = true, hydrate2 = true) {
    context._value = context.value = node.hook.commit.dispatch(context._value);
    if (node.type !== "input" && hydrate2)
      node.hydrate();
    node.emit("commitRaw", context.value);
    node.emit("commit", context.value);
    if (calm2)
      node.calm();
  }
  function partial(context, { name, value, from }) {
    if (Object.isFrozen(context._value))
      return;
    if (isList(context)) {
      const insert = value === valueRemoved ? [] : value === valueMoved && typeof from === "number" ? context._value.splice(from, 1) : [value];
      context._value.splice(
        name,
        value === valueMoved || from === valueInserted ? 0 : 1,
        ...insert
      );
      return;
    }
    if (value !== valueRemoved) {
      context._value[name] = value;
    } else {
      delete context._value[name];
    }
  }
  function hydrate(node, context) {
    const _value = context._value;
    if (node.type === "list" && node.sync)
      syncListNodes(node, context);
    context.children.forEach((child) => {
      if (typeof _value !== "object")
        return;
      if (child.name in _value) {
        const childValue = child.type !== "input" || _value[child.name] && typeof _value[child.name] === "object" ? init(_value[child.name]) : _value[child.name];
        if (!child.isSettled || (!isObject(childValue) || child.props.mergeStrategy) && eq(childValue, child._value))
          return;
        child.input(childValue, false);
      } else {
        if (node.type !== "list" || typeof child.name === "number") {
          partial(context, { name: child.name, value: child.value });
        }
        if (!_value.__init) {
          if (child.type === "group")
            child.input({}, false);
          else if (child.type === "list")
            child.input([], false);
          else
            child.input(void 0, false);
        }
      }
    });
    return node;
  }
  function syncListNodes(node, context) {
    const _value = node._value;
    if (!Array.isArray(_value))
      return;
    const newChildren = [];
    const unused = new Set(context.children);
    const placeholderValues = /* @__PURE__ */ new Map();
    _value.forEach((value, i) => {
      if (context.children[i] && context.children[i]._value === value) {
        newChildren.push(context.children[i]);
        unused.delete(context.children[i]);
      } else {
        newChildren.push(null);
        const indexes = placeholderValues.get(value) || [];
        indexes.push(i);
        placeholderValues.set(value, indexes);
      }
    });
    if (unused.size && placeholderValues.size) {
      unused.forEach((child) => {
        if (placeholderValues.has(child._value)) {
          const indexes = placeholderValues.get(child._value);
          const index = indexes.shift();
          newChildren[index] = child;
          unused.delete(child);
          if (!indexes.length)
            placeholderValues.delete(child._value);
        }
      });
    }
    const emptyIndexes = [];
    placeholderValues.forEach((indexes) => {
      emptyIndexes.push(...indexes);
    });
    while (unused.size && emptyIndexes.length) {
      const child = unused.values().next().value;
      const index = emptyIndexes.shift();
      if (index === void 0)
        break;
      newChildren[index] = child;
      unused.delete(child);
    }
    emptyIndexes.forEach((index, value) => {
      newChildren[index] = createPlaceholder({ value });
    });
    if (unused.size) {
      unused.forEach((child) => {
        if (!("__FKP" in child)) {
          const parent = child._c.parent;
          if (!parent || isPlaceholder(parent))
            return;
          parent.ledger.unmerge(child);
          child._c.parent = null;
          child.destroy();
        }
      });
    }
    context.children = newChildren;
  }
  function disturb(node, context) {
    if (context._d <= 0) {
      context.isSettled = false;
      node.emit("settled", false, false);
      context.settled = new Promise((resolve) => {
        context._resolve = resolve;
      });
      if (node.parent)
        node.parent?.disturb();
    }
    context._d++;
    return node;
  }
  function calm(node, context, value) {
    if (value !== void 0 && node.type !== "input") {
      partial(context, value);
      const shouldHydrate = !!(node.config.mergeStrategy && node.config.mergeStrategy[value.name]);
      return commit(node, context, true, shouldHydrate);
    }
    if (context._d > 0)
      context._d--;
    if (context._d === 0) {
      context.isSettled = true;
      node.emit("settled", true, false);
      if (node.parent)
        node.parent?.calm({ name: node.name, value: context.value });
      if (context._resolve)
        context._resolve(context.value);
    }
  }
  function destroy(node, context) {
    node.emit("destroying", node);
    node.store.filter(() => false);
    if (node.parent) {
      node.parent.remove(node);
    }
    deregister(node);
    node.emit("destroyed", node);
    context._e.flush();
    context._value = context.value = void 0;
    for (const property in context.context) {
      delete context.context[property];
    }
    context.plugins.clear();
    context.context = null;
  }
  function define(node, context, definition3) {
    context.type = definition3.type;
    const clonedDef = clone(definition3);
    node.props.__propDefs = mergeProps(
      node.props.__propDefs ?? [],
      clonedDef?.props || []
    );
    clonedDef.props = node.props.__propDefs;
    context.props.definition = clonedDef;
    context.value = context._value = createValue({
      type: node.type,
      value: context.value
    });
    if (definition3.forceTypeProp) {
      if (node.props.type)
        node.props.originalType = node.props.type;
      context.props.type = definition3.forceTypeProp;
    }
    if (definition3.family) {
      context.props.family = definition3.family;
    }
    if (definition3.features) {
      definition3.features.forEach((feature) => feature(node));
    }
    if (definition3.props) {
      node.addProps(definition3.props);
    }
    node.emit("defined", definition3);
  }
  function addProps(node, context, props) {
    const propNames = Array.isArray(props) ? props : Object.keys(props);
    const defaults = !Array.isArray(props) ? propNames.reduce((defaults2, name) => {
      if ("default" in props[name]) {
        defaults2[name] = props[name].default;
      }
      return defaults2;
    }, {}) : {};
    if (node.props.attrs) {
      const attrs = { ...node.props.attrs };
      node.props._emit = false;
      for (const attr in attrs) {
        const camelName = camel(attr);
        if (propNames.includes(camelName)) {
          node.props[camelName] = attrs[attr];
          delete attrs[attr];
        }
      }
      if (!Array.isArray(props)) {
        propNames.forEach((prop) => {
          if ("default" in props[prop] && node.props[prop] === void 0) {
            node.props[prop] = defaults[prop];
          }
        });
      }
      const initial = cloneAny(context._value);
      node.props.initial = node.type !== "input" ? init(initial) : initial;
      node.props._emit = true;
      node.props.attrs = attrs;
    }
    const mergedProps = mergeProps(node.props.__propDefs ?? [], props);
    if (node.props.definition) {
      node.props.definition.props = mergedProps;
    }
    node.props.__propDefs = mergedProps;
    node.emit("added-props", props);
    return node;
  }
  function toPropsObj(props) {
    return !Array.isArray(props) ? props : props.reduce((props2, prop) => {
      props2[prop] = {};
      return props2;
    }, {});
  }
  function mergeProps(props, newProps) {
    if (Array.isArray(props) && Array.isArray(newProps))
      return props.concat(newProps);
    return extend(toPropsObj(props), toPropsObj(newProps));
  }
  function addChild(parent, parentContext, child, listIndex) {
    if (parent.type === "input")
      error(100, parent);
    if (child.parent && child.parent !== parent) {
      child.parent.remove(child);
    }
    if (!parentContext.children.includes(child)) {
      if (listIndex !== void 0 && parent.type === "list") {
        const existingNode = parentContext.children[listIndex];
        if (existingNode && "__FKP" in existingNode) {
          child._c.uid = existingNode.uid;
          parentContext.children.splice(listIndex, 1, child);
        } else {
          parentContext.children.splice(listIndex, 0, child);
        }
        if (Array.isArray(parent.value) && parent.value.length < parentContext.children.length) {
          parent.disturb().calm({
            name: listIndex,
            value: child.value,
            from: valueInserted
          });
        }
      } else {
        parentContext.children.push(child);
      }
      if (!child.isSettled)
        parent.disturb();
    }
    if (child.parent !== parent) {
      child.parent = parent;
      if (child.parent !== parent) {
        parent.remove(child);
        child.parent.add(child);
        return parent;
      }
    } else {
      child.use(parent.plugins);
    }
    commit(parent, parentContext, false);
    parent.ledger.merge(child);
    parent.emit("child", child);
    return parent;
  }
  function setParent(child, context, _property, parent) {
    if (isNode(parent)) {
      if (child.parent && child.parent !== parent) {
        child.parent.remove(child);
      }
      context.parent = parent;
      child.resetConfig();
      !parent.children.includes(child) ? parent.add(child) : child.use(parent.plugins);
      return true;
    }
    if (parent === null) {
      context.parent = null;
      return true;
    }
    return false;
  }
  function removeChild(node, context, child) {
    const childIndex = context.children.indexOf(child);
    if (childIndex !== -1) {
      if (child.isSettled)
        node.disturb();
      context.children.splice(childIndex, 1);
      let preserve = undefine(child.props.preserve);
      let parent = child.parent;
      while (preserve === void 0 && parent) {
        preserve = undefine(parent.props.preserve);
        parent = parent.parent;
      }
      if (!preserve) {
        node.calm({
          name: node.type === "list" ? childIndex : child.name,
          value: valueRemoved
        });
      } else {
        node.calm();
      }
      child.parent = null;
      child.config._rmn = child;
    }
    node.ledger.unmerge(child);
    node.emit("childRemoved", child);
    return node;
  }
  function eachChild(_node, context, callback) {
    context.children.forEach((child) => !("__FKP" in child) && callback(child));
  }
  function walkTree(_node, context, callback, stopIfFalse = false, skipSubtreeOnFalse = false) {
    context.children.some((child) => {
      if ("__FKP" in child)
        return false;
      const val = callback(child);
      if (stopIfFalse && val === false)
        return true;
      if (skipSubtreeOnFalse && val === false)
        return false;
      return child.walk(callback, stopIfFalse, skipSubtreeOnFalse);
    });
  }
  function resetConfig(node, context) {
    const parent = node.parent || void 0;
    context.config = createConfig2(node.config._t, parent);
    node.walk((n) => n.resetConfig());
  }
  function use(node, context, plugin2, run2 = true, library = true) {
    if (Array.isArray(plugin2) || plugin2 instanceof Set) {
      plugin2.forEach((p) => use(node, context, p));
      return node;
    }
    if (!context.plugins.has(plugin2)) {
      if (library && typeof plugin2.library === "function")
        plugin2.library(node);
      if (run2 && plugin2(node) !== false) {
        context.plugins.add(plugin2);
        node.children.forEach((child) => child.use(plugin2));
      }
    }
    return node;
  }
  function setIndex(node, _context, _property, setIndex2) {
    if (isNode(node.parent)) {
      const children = node.parent.children;
      const index = setIndex2 >= children.length ? children.length - 1 : setIndex2 < 0 ? 0 : setIndex2;
      const oldIndex = children.indexOf(node);
      if (oldIndex === -1)
        return false;
      children.splice(oldIndex, 1);
      children.splice(index, 0, node);
      node.parent.children = children;
      if (node.parent.type === "list")
        node.parent.disturb().calm({ name: index, value: valueMoved, from: oldIndex });
      return true;
    }
    return false;
  }
  function getIndex(node) {
    if (node.parent) {
      const index = [...node.parent.children].indexOf(node);
      return index === -1 ? node.parent.children.length : index;
    }
    return -1;
  }
  function getContext(_node, context) {
    return context;
  }
  function getName(node, context) {
    if (node.parent?.type === "list")
      return node.index;
    return context.name !== useIndex ? context.name : node.index;
  }
  function getAddress(node, context) {
    return context.parent ? context.parent.address.concat([node.name]) : [node.name];
  }
  function getNode2(node, _context, locator) {
    const address = typeof locator === "string" ? locator.split(node.config.delimiter) : locator;
    if (!address.length)
      return void 0;
    const first = address[0];
    let pointer = node.parent;
    if (!pointer) {
      if (String(address[0]) === String(node.name))
        address.shift();
      pointer = node;
    }
    if (first === "$parent")
      address.shift();
    while (pointer && address.length) {
      const name = address.shift();
      switch (name) {
        case "$root":
          pointer = node.root;
          break;
        case "$parent":
          pointer = pointer.parent;
          break;
        case "$self":
          pointer = node;
          break;
        default:
          pointer = pointer.children.find(
            (c) => !("__FKP" in c) && String(c.name) === String(name)
          ) || select(pointer, name);
      }
    }
    return pointer || void 0;
  }
  function select(node, selector) {
    const matches3 = String(selector).match(/^(find)\((.*)\)$/);
    if (matches3) {
      const [, action, argStr] = matches3;
      const args = argStr.split(",").map((arg) => arg.trim());
      switch (action) {
        case "find":
          return node.find(args[0], args[1]);
        default:
          return void 0;
      }
    }
    return void 0;
  }
  function find(node, _context, searchTerm, searcher) {
    return bfs(node, searchTerm, searcher);
  }
  function bfs(tree, searchValue, searchGoal = "name") {
    const search = typeof searchGoal === "string" ? (n) => n[searchGoal] == searchValue : searchGoal;
    const stack = [tree];
    while (stack.length) {
      const node = stack.shift();
      if ("__FKP" in node)
        continue;
      if (search(node, searchValue))
        return node;
      stack.push(...node.children);
    }
    return void 0;
  }
  function getRoot(n) {
    let node = n;
    while (node.parent) {
      node = node.parent;
    }
    return node;
  }
  function createConfig2(target = {}, parent) {
    let node = void 0;
    return new Proxy(target, {
      get(...args) {
        const prop = args[1];
        if (prop === "_t")
          return target;
        const localValue = Reflect.get(...args);
        if (localValue !== void 0)
          return localValue;
        if (parent) {
          const parentVal = parent.config[prop];
          if (parentVal !== void 0)
            return parentVal;
        }
        if (target.rootConfig && typeof prop === "string") {
          const rootValue = target.rootConfig[prop];
          if (rootValue !== void 0)
            return rootValue;
        }
        if (prop === "delay" && node?.type === "input")
          return 20;
        return defaultConfig[prop];
      },
      set(...args) {
        const prop = args[1];
        const value = args[2];
        if (prop === "_n") {
          node = value;
          if (target.rootConfig)
            target.rootConfig._add(node);
          return true;
        }
        if (prop === "_rmn") {
          if (target.rootConfig)
            target.rootConfig._rm(node);
          node = void 0;
          return true;
        }
        if (!eq(target[prop], value, false)) {
          const didSet = Reflect.set(...args);
          if (node) {
            node.emit(`config:${prop}`, value, false);
            configChange(node, prop, value);
            node.walk((n) => configChange(n, prop, value), false, true);
          }
          return didSet;
        }
        return true;
      }
    });
  }
  function text(node, _context, key, type = "ui") {
    const fragment2 = typeof key === "string" ? { key, value: key, type } : key;
    const value = node.hook.text.dispatch(fragment2);
    node.emit("text", value, false);
    return value.value;
  }
  function submit(node) {
    const name = node.name;
    do {
      if (node.props.isForm === true)
        break;
      if (!node.parent)
        error(106, name);
      node = node.parent;
    } while (node);
    if (node.props.id) {
      submitForm(node.props.id, node.props.__root);
    }
  }
  function resetValue(node, _context, value) {
    return reset(node, value);
  }
  function setErrors(node, _context, localErrors, childErrors) {
    const sourceKey = `${node.name}-set`;
    const errors2 = node.hook.setErrors.dispatch({ localErrors, childErrors });
    createMessages(node, errors2.localErrors, errors2.childErrors).forEach(
      (errors22) => {
        node.store.apply(errors22, (message4) => message4.meta.source === sourceKey);
      }
    );
    return node;
  }
  function clearErrors(node, _context, clearChildErrors = true, sourceKey) {
    node.store.filter((m) => {
      return !(sourceKey === void 0 || m.meta.source === sourceKey);
    }, "error");
    if (clearChildErrors) {
      sourceKey = sourceKey || `${node.name}-set`;
      node.walk((child) => {
        child.store.filter((message4) => {
          return !(message4.type === "error" && message4.meta && message4.meta.source === sourceKey);
        });
      });
    }
    return node;
  }
  function createProps(initial) {
    const props = {
      initial: typeof initial === "object" ? cloneAny(initial) : initial
    };
    let node;
    let isEmitting = true;
    let propDefs = {};
    return new Proxy(props, {
      get(...args) {
        const [_t, prop] = args;
        let val;
        if (has(props, prop)) {
          val = Reflect.get(...args);
          if (propDefs[prop]?.boolean)
            val = boolGetter(val);
        } else if (node && typeof prop === "string" && node.config[prop] !== void 0) {
          val = node.config[prop];
          if (prop === "mergeStrategy" && node?.type === "input" && isRecord(val) && node.name in val) {
            val = val[node.name];
          }
        } else {
          val = propDefs[prop]?.default;
        }
        const getter = propDefs[prop]?.getter;
        if (propDefs[prop]?.boolean)
          val = !!val;
        return getter ? getter(val, node) : val;
      },
      set(target, property, originalValue, receiver) {
        if (property === "_n") {
          node = originalValue;
          return true;
        }
        if (property === "_emit") {
          isEmitting = originalValue;
          return true;
        }
        let { prop, value } = node.hook.prop.dispatch({
          prop: property,
          value: originalValue
        });
        const setter = propDefs[prop]?.setter;
        value = setter ? setter(value, node) : value;
        if (!eq(props[prop], value, false) || typeof value === "object") {
          const didSet = Reflect.set(target, prop, value, receiver);
          if (prop === "__propDefs")
            propDefs = toPropsObj(value);
          if (isEmitting) {
            node.emit("prop", { prop, value });
            if (typeof prop === "string")
              node.emit(`prop:${prop}`, value);
          }
          return didSet;
        }
        return true;
      }
    });
  }
  function extend2(node, context, property, trap2) {
    context.traps.set(property, trap2);
    return node;
  }
  function findDefinition(node, plugins) {
    if (node.props.definition)
      return node.define(node.props.definition);
    for (const plugin2 of plugins) {
      if (node.props.definition)
        return;
      if (typeof plugin2.library === "function") {
        plugin2.library(node);
      }
    }
  }
  function createContext(options2) {
    const value = createValue(options2);
    const config = createConfig2(options2.config || {}, options2.parent);
    return {
      _d: 0,
      _e: createEmitter(),
      uid: Symbol(),
      _resolve: false,
      _tmo: false,
      _value: value,
      children: dedupe(options2.children || []),
      config,
      hook: createHooks(),
      isCreated: false,
      isSettled: true,
      ledger: createLedger(),
      name: createName(options2),
      parent: options2.parent || null,
      plugins: /* @__PURE__ */ new Set(),
      props: createProps(value),
      settled: Promise.resolve(value),
      store: createStore(true),
      sync: options2.sync || false,
      traps: createTraps(),
      type: options2.type || "input",
      value
    };
  }
  function nodeInit(node, options2) {
    const hasInitialId = options2.props?.id;
    if (!hasInitialId)
      delete options2.props?.id;
    node.ledger.init(node.store._n = node.props._n = node.config._n = node);
    node.props._emit = false;
    Object.assign(
      node.props,
      hasInitialId ? {} : { id: `input_${idCount++}` },
      options2.props ?? {}
    );
    node.props._emit = true;
    findDefinition(
      node,
      /* @__PURE__ */ new Set([
        ...options2.plugins || [],
        ...node.parent ? node.parent.plugins : []
      ])
    );
    if (options2.plugins) {
      for (const plugin2 of options2.plugins) {
        use(node, node._c, plugin2, true, false);
      }
    }
    node.each((child) => node.add(child));
    if (node.parent)
      node.parent.add(node, options2.index);
    if (node.type === "input" && node.children.length)
      error(100, node);
    input(node, node._c, node._value, false);
    node.store.release();
    if (hasInitialId)
      register(node);
    node.emit("created", node);
    node.isCreated = true;
    return node;
  }
  function createPlaceholder(options2) {
    return {
      __FKP: true,
      uid: Symbol(),
      name: options2?.name ?? `p_${nameCount++}`,
      value: options2?.value ?? null,
      _value: options2?.value ?? null,
      type: options2?.type ?? "input",
      props: {},
      use: () => {
      },
      input(value) {
        this._value = value;
        this.value = value;
        return Promise.resolve();
      },
      isSettled: true
    };
  }
  function isPlaceholder(node) {
    return "__FKP" in node;
  }
  function createNode(options2) {
    const ops = options2 || {};
    const context = createContext(ops);
    const node = new Proxy(context, {
      get(...args) {
        const [, property] = args;
        if (property === "__FKNode__")
          return true;
        const trap2 = context.traps.get(property);
        if (trap2 && trap2.get)
          return trap2.get(node, context);
        return Reflect.get(...args);
      },
      set(...args) {
        const [, property, value] = args;
        const trap2 = context.traps.get(property);
        if (trap2 && trap2.set)
          return trap2.set(node, context, property, value);
        return Reflect.set(...args);
      }
    });
    return nodeInit(node, ops);
  }
  function isDOM(node) {
    return typeof node !== "string" && has(node, "$el");
  }
  function isComponent(node) {
    return typeof node !== "string" && has(node, "$cmp");
  }
  function isConditional(node) {
    if (!node || typeof node === "string")
      return false;
    return has(node, "if") && has(node, "then");
  }
  function isSugar(node) {
    return typeof node !== "string" && "$formkit" in node;
  }
  function sugar(node) {
    if (typeof node === "string") {
      return {
        $el: "text",
        children: node
      };
    }
    if (isSugar(node)) {
      const {
        $formkit: type,
        for: iterator,
        if: condition,
        children,
        bind,
        ...props
      } = node;
      return Object.assign(
        {
          $cmp: "FormKit",
          props: { ...props, type }
        },
        condition ? { if: condition } : {},
        iterator ? { for: iterator } : {},
        children ? { children } : {},
        bind ? { bind } : {}
      );
    }
    return node;
  }
  function compile(expr) {
    let provideTokens;
    const requirements = /* @__PURE__ */ new Set();
    const x = function expand(operand, tokens) {
      return typeof operand === "function" ? operand(tokens) : operand;
    };
    const operatorRegistry = [
      {
        "&&": (l, r, t) => x(l, t) && x(r, t),
        "||": (l, r, t) => x(l, t) || x(r, t)
      },
      {
        "===": (l, r, t) => !!(x(l, t) === x(r, t)),
        "!==": (l, r, t) => !!(x(l, t) !== x(r, t)),
        "==": (l, r, t) => !!(x(l, t) == x(r, t)),
        "!=": (l, r, t) => !!(x(l, t) != x(r, t)),
        ">=": (l, r, t) => !!(x(l, t) >= x(r, t)),
        "<=": (l, r, t) => !!(x(l, t) <= x(r, t)),
        ">": (l, r, t) => !!(x(l, t) > x(r, t)),
        "<": (l, r, t) => !!(x(l, t) < x(r, t))
      },
      {
        "+": (l, r, t) => x(l, t) + x(r, t),
        "-": (l, r, t) => x(l, t) - x(r, t)
      },
      {
        "*": (l, r, t) => x(l, t) * x(r, t),
        "/": (l, r, t) => x(l, t) / x(r, t),
        "%": (l, r, t) => x(l, t) % x(r, t)
      }
    ];
    const operatorSymbols = operatorRegistry.reduce((s, g) => {
      return s.concat(Object.keys(g));
    }, []);
    const operatorChars = new Set(operatorSymbols.map((key) => key.charAt(0)));
    function getOp(symbols, char, p, expression) {
      const candidates = symbols.filter((s) => s.startsWith(char));
      if (!candidates.length)
        return false;
      return candidates.find((symbol2) => {
        if (expression.length >= p + symbol2.length) {
          const nextChars = expression.substring(p, p + symbol2.length);
          if (nextChars === symbol2)
            return symbol2;
        }
        return false;
      });
    }
    function getStep(p, expression, direction = 1) {
      let next = direction ? expression.substring(p + 1).trim() : expression.substring(0, p).trim();
      if (!next.length)
        return -1;
      if (!direction) {
        const reversed = next.split("").reverse();
        const start = reversed.findIndex((char2) => operatorChars.has(char2));
        next = reversed.slice(start).join("");
      }
      const char = next[0];
      return operatorRegistry.findIndex((operators) => {
        const symbols = Object.keys(operators);
        return !!getOp(symbols, char, 0, next);
      });
    }
    function getTail(pos, expression) {
      let tail = "";
      const length3 = expression.length;
      let depth = 0;
      for (let p = pos; p < length3; p++) {
        const char = expression.charAt(p);
        if (char === "(") {
          depth++;
        } else if (char === ")") {
          depth--;
        } else if (depth === 0 && char === " ") {
          continue;
        }
        if (depth === 0 && getOp(operatorSymbols, char, p, expression)) {
          return [tail, p - 1];
        } else {
          tail += char;
        }
      }
      return [tail, expression.length - 1];
    }
    function parseLogicals(expression, step = 0) {
      const operators = operatorRegistry[step];
      const length3 = expression.length;
      const symbols = Object.keys(operators);
      let depth = 0;
      let quote = false;
      let op = null;
      let operand = "";
      let left = null;
      let operation;
      let lastChar = "";
      let char = "";
      let parenthetical = "";
      let parenQuote = "";
      let startP = 0;
      const addTo = (depth2, char2) => {
        depth2 ? parenthetical += char2 : operand += char2;
      };
      for (let p = 0; p < length3; p++) {
        lastChar = char;
        char = expression.charAt(p);
        if ((char === "'" || char === '"') && lastChar !== "\\" && (depth === 0 && !quote || depth && !parenQuote)) {
          if (depth) {
            parenQuote = char;
          } else {
            quote = char;
          }
          addTo(depth, char);
          continue;
        } else if (quote && (char !== quote || lastChar === "\\") || parenQuote && (char !== parenQuote || lastChar === "\\")) {
          addTo(depth, char);
          continue;
        } else if (quote === char) {
          quote = false;
          addTo(depth, char);
          continue;
        } else if (parenQuote === char) {
          parenQuote = false;
          addTo(depth, char);
          continue;
        } else if (char === " ") {
          continue;
        } else if (char === "(") {
          if (depth === 0) {
            startP = p;
          } else {
            parenthetical += char;
          }
          depth++;
        } else if (char === ")") {
          depth--;
          if (depth === 0) {
            const fn = typeof operand === "string" && operand.startsWith("$") ? operand : void 0;
            const hasTail = fn && expression.charAt(p + 1) === ".";
            let tail = "";
            if (hasTail) {
              [tail, p] = getTail(p + 2, expression);
            }
            const lStep = op ? step : getStep(startP, expression, 0);
            const rStep = getStep(p, expression);
            if (lStep === -1 && rStep === -1) {
              operand = evaluate(parenthetical, -1, fn, tail);
              if (typeof operand === "string")
                operand = parenthetical;
            } else if (op && (lStep >= rStep || rStep === -1) && step === lStep) {
              left = op.bind(null, evaluate(parenthetical, -1, fn, tail));
              op = null;
              operand = "";
            } else if (rStep > lStep && step === rStep) {
              operand = evaluate(parenthetical, -1, fn, tail);
            } else {
              operand += `(${parenthetical})${hasTail ? `.${tail}` : ""}`;
            }
            parenthetical = "";
          } else {
            parenthetical += char;
          }
        } else if (depth === 0 && (operation = getOp(symbols, char, p, expression))) {
          if (p === 0) {
            error(103, [operation, expression]);
          }
          p += operation.length - 1;
          if (p === expression.length - 1) {
            error(104, [operation, expression]);
          }
          if (!op) {
            if (left) {
              op = operators[operation].bind(null, evaluate(left, step));
              left = null;
            } else {
              op = operators[operation].bind(null, evaluate(operand, step));
              operand = "";
            }
          } else if (operand) {
            left = op.bind(null, evaluate(operand, step));
            op = operators[operation].bind(null, left);
            operand = "";
          }
          continue;
        } else {
          addTo(depth, char);
        }
      }
      if (operand && op) {
        op = op.bind(null, evaluate(operand, step));
      }
      op = !op && left ? left : op;
      if (!op && operand) {
        op = (v, t) => {
          return typeof v === "function" ? v(t) : v;
        };
        op = op.bind(null, evaluate(operand, step));
      }
      if (!op && !operand) {
        error(105, expression);
      }
      return op;
    }
    function evaluate(operand, step, fnToken, tail) {
      if (fnToken) {
        const fn = evaluate(fnToken, operatorRegistry.length);
        let userFuncReturn;
        let tailCall = tail ? compile(`$${tail}`) : false;
        if (typeof fn === "function") {
          const args = parseArgs(String(operand)).map(
            (arg) => evaluate(arg, -1)
          );
          return (tokens) => {
            const userFunc = fn(tokens);
            if (typeof userFunc !== "function") {
              warn(150, fnToken);
              return userFunc;
            }
            userFuncReturn = userFunc(
              ...args.map(
                (arg) => typeof arg === "function" ? arg(tokens) : arg
              )
            );
            if (tailCall) {
              tailCall = tailCall.provide((subTokens) => {
                const rootTokens = provideTokens(subTokens);
                const t = subTokens.reduce(
                  (tokenSet, token3) => {
                    const isTail = token3 === tail || tail?.startsWith(`${token3}(`);
                    if (isTail) {
                      const value = getAt(userFuncReturn, token3);
                      tokenSet[token3] = () => value;
                    } else {
                      tokenSet[token3] = rootTokens[token3];
                    }
                    return tokenSet;
                  },
                  {}
                );
                return t;
              });
            }
            return tailCall ? tailCall() : userFuncReturn;
          };
        }
      } else if (typeof operand === "string") {
        if (operand === "true")
          return true;
        if (operand === "false")
          return false;
        if (operand === "undefined")
          return void 0;
        if (isQuotedString(operand))
          return rmEscapes(operand.substring(1, operand.length - 1));
        if (!isNaN(+operand))
          return Number(operand);
        if (step < operatorRegistry.length - 1) {
          return parseLogicals(operand, step + 1);
        } else {
          if (operand.startsWith("$")) {
            const cleaned = operand.substring(1);
            requirements.add(cleaned);
            return function getToken(tokens) {
              return cleaned in tokens ? tokens[cleaned]() : void 0;
            };
          }
          return operand;
        }
      }
      return operand;
    }
    const compiled = parseLogicals(
      expr.startsWith("$:") ? expr.substring(2) : expr
    );
    const reqs = Array.from(requirements);
    function provide4(callback) {
      provideTokens = callback;
      return Object.assign(
        // @ts-ignore - @rollup/plugin-typescript doesn't like this
        compiled.bind(null, callback(reqs)),
        { provide: provide4 }
      );
    }
    return Object.assign(compiled, {
      provide: provide4
    });
  }
  function createClasses(propertyKey, node, sectionClassList) {
    if (!sectionClassList)
      return {};
    if (typeof sectionClassList === "string") {
      const classKeys = sectionClassList.split(" ");
      return classKeys.reduce(
        (obj, key) => Object.assign(obj, { [key]: true }),
        {}
      );
    } else if (typeof sectionClassList === "function") {
      return createClasses(
        propertyKey,
        node,
        sectionClassList(node, propertyKey)
      );
    }
    return sectionClassList;
  }
  function generateClassList(node, property, ...args) {
    const combinedClassList = args.reduce((finalClassList, currentClassList) => {
      if (!currentClassList)
        return handleNegativeClasses(finalClassList);
      const { $reset, ...classList } = currentClassList;
      if ($reset) {
        return handleNegativeClasses(classList);
      }
      return handleNegativeClasses(Object.assign(finalClassList, classList));
    }, {});
    return Object.keys(
      node.hook.classes.dispatch({ property, classes: combinedClassList }).classes
    ).filter((key) => combinedClassList[key]).join(" ") || null;
  }
  function handleNegativeClasses(classList) {
    const removalToken = "$remove:";
    let hasNegativeClassValue = false;
    const applicableClasses = Object.keys(classList).filter((className) => {
      if (classList[className] && className.startsWith(removalToken)) {
        hasNegativeClassValue = true;
      }
      return classList[className];
    });
    if (applicableClasses.length > 1 && hasNegativeClassValue) {
      const negativeClasses = applicableClasses.filter((className) => className.startsWith(removalToken));
      negativeClasses.map((negativeClass) => {
        const targetClass = negativeClass.substring(removalToken.length);
        classList[targetClass] = false;
        classList[negativeClass] = false;
      });
    }
    return classList;
  }
  function setErrors2(id, localErrors, childErrors) {
    const node = getNode(id);
    if (node) {
      node.setErrors(localErrors, childErrors);
    } else {
      warn(651, id);
    }
  }
  function clearErrors2(id, clearChildren = true) {
    const node = getNode(id);
    if (node) {
      node.clearErrors(clearChildren);
    } else {
      warn(652, id);
    }
  }
  exports.errorHandler = void 0; var warningHandler, storeTraps, registry, reflected, emit2, receipts, defaultConfig, useIndex, valueRemoved, valueMoved, valueInserted, invalidSetter, traps, nameCount, idCount, FORMKIT_VERSION;
  var init_dist2 = __esm({
    "packages/core/dist/index.mjs"() {
      init_dist();
      exports.errorHandler = createDispatcher();
      exports.errorHandler((error2, next) => {
        if (!error2.message)
          error2.message = String(`E${error2.code}`);
        return next(error2);
      });
      warningHandler = createDispatcher();
      warningHandler((warning, next) => {
        if (!warning.message)
          warning.message = String(`W${warning.code}`);
        const result = next(warning);
        if (console && typeof console.warn === "function")
          console.warn(result.message);
        return result;
      });
      storeTraps = {
        apply: applyMessages,
        set: setMessage,
        remove: removeMessage,
        filter: filterMessages,
        reduce: reduceMessages,
        release: releaseBuffer,
        touch: touchMessages
      };
      registry = /* @__PURE__ */ new Map();
      reflected = /* @__PURE__ */ new Map();
      emit2 = createEmitter();
      receipts = [];
      defaultConfig = {
        delimiter: ".",
        delay: 0,
        locale: "en",
        rootClasses: (key) => ({ [`formkit-${kebab(key)}`]: true })
      };
      useIndex = Symbol("index");
      valueRemoved = Symbol("removed");
      valueMoved = Symbol("moved");
      valueInserted = Symbol("inserted");
      invalidSetter = (node, _context, property) => {
        error(102, [node, property]);
      };
      traps = {
        _c: trap(getContext, invalidSetter, false),
        add: trap(addChild),
        addProps: trap(addProps),
        address: trap(getAddress, invalidSetter, false),
        at: trap(getNode2),
        bubble: trap(bubble),
        clearErrors: trap(clearErrors),
        calm: trap(calm),
        config: trap(false),
        define: trap(define),
        disturb: trap(disturb),
        destroy: trap(destroy),
        extend: trap(extend2),
        hydrate: trap(hydrate),
        index: trap(getIndex, setIndex, false),
        input: trap(input),
        each: trap(eachChild),
        emit: trap(emit),
        find: trap(find),
        on: trap(on),
        off: trap(off),
        parent: trap(false, setParent),
        plugins: trap(false),
        remove: trap(removeChild),
        root: trap(getRoot, invalidSetter, false),
        reset: trap(resetValue),
        resetConfig: trap(resetConfig),
        setErrors: trap(setErrors),
        submit: trap(submit),
        t: trap(text),
        use: trap(use),
        name: trap(getName, false, false),
        walk: trap(walkTree)
      };
      nameCount = 0;
      idCount = 0;
      FORMKIT_VERSION = "__FKV__";
    }
  });

  // packages/inputs/dist/index.mjs
  function createLibraryPlugin(...libraries) {
    const library = libraries.reduce(
      (merged, lib) => extend(merged, lib),
      {}
    );
    const plugin2 = () => {
    };
    plugin2.library = function(node) {
      const type = camel(node.props.type);
      if (has(library, type)) {
        node.define(library[type]);
      }
    };
    return plugin2;
  }
  function isGroupOption(option2) {
    return option2 && typeof option2 === "object" && "group" in option2 && Array.isArray(option2.options);
  }
  function normalizeOptions(options2, i = { count: 1 }) {
    if (Array.isArray(options2)) {
      return options2.map(
        (option2) => {
          if (typeof option2 === "string" || typeof option2 === "number") {
            return {
              label: String(option2),
              value: String(option2)
            };
          }
          if (typeof option2 == "object") {
            if ("group" in option2) {
              option2.options = normalizeOptions(option2.options || [], i);
              return option2;
            } else if ("value" in option2 && typeof option2.value !== "string") {
              Object.assign(option2, {
                value: `__mask_${i.count++}`,
                __original: option2.value
              });
            }
          }
          return option2;
        }
      );
    }
    return Object.keys(options2).map((value) => {
      return {
        label: options2[value],
        value
      };
    });
  }
  function optionValue(options2, value, undefinedIfNotFound = false) {
    if (Array.isArray(options2)) {
      for (const option2 of options2) {
        if (typeof option2 !== "object" && option2)
          continue;
        if (isGroupOption(option2)) {
          const found = optionValue(option2.options, value, true);
          if (found !== void 0) {
            return found;
          }
        } else if (value == option2.value) {
          return "__original" in option2 ? option2.__original : option2.value;
        }
      }
    }
    return undefinedIfNotFound ? void 0 : value;
  }
  function shouldSelect(valueA, valueB) {
    if (valueA === null && valueB === void 0 || valueA === void 0 && valueB === null)
      return false;
    if (valueA == valueB)
      return true;
    if (isPojo(valueA) && isPojo(valueB))
      return eq(valueA, valueB);
    return false;
  }
  function options(node) {
    node.hook.prop((prop, next) => {
      var _a;
      if (prop.prop === "options") {
        if (typeof prop.value === "function") {
          node.props.optionsLoader = prop.value;
          prop.value = [];
        } else {
          (_a = node.props)._normalizeCounter ?? (_a._normalizeCounter = { count: 1 });
          prop.value = normalizeOptions(prop.value, node.props._normalizeCounter);
        }
      }
      return next(prop);
    });
  }
  // @__NO_SIDE_EFFECTS__
  function createSection(section, el, fragment2 = false) {
    return (...children) => {
      const extendable = (extensions) => {
        const node = !el || typeof el === "string" ? { $el: el } : el();
        if (isDOM(node) || isComponent(node)) {
          if (!node.meta) {
            node.meta = { section };
          } else {
            node.meta.section = section;
          }
          if (children.length && !node.children) {
            node.children = [
              ...children.map(
                (child) => typeof child === "function" ? child(extensions) : child
              )
            ];
          }
          if (isDOM(node)) {
            node.attrs = {
              class: `$classes.${section}`,
              ...node.attrs || {}
            };
          }
        }
        return {
          if: `$slots.${section}`,
          then: `$slots.${section}`,
          else: section in extensions ? /* @__PURE__ */ extendSchema(node, extensions[section]) : node
        };
      };
      extendable._s = section;
      return fragment2 ? /* @__PURE__ */ createRoot(extendable) : extendable;
    };
  }
  // @__NO_SIDE_EFFECTS__
  function createRoot(rootSection) {
    return (extensions) => {
      return [rootSection(extensions)];
    };
  }
  function isSchemaObject(schema) {
    return !!(schema && typeof schema === "object" && ("$el" in schema || "$cmp" in schema || "$formkit" in schema));
  }
  // @__NO_SIDE_EFFECTS__
  function extendSchema(schema, extension = {}) {
    if (typeof schema === "string") {
      return isSchemaObject(extension) || typeof extension === "string" ? extension : schema;
    } else if (Array.isArray(schema)) {
      return isSchemaObject(extension) ? extension : schema;
    }
    return extend(schema, extension);
  }
  function resetRadio() {
    radioInstance = 0;
  }
  function renamesRadios(node) {
    if (node.type === "group" || node.type === "list") {
      node.plugins.add(renamesRadiosPlugin);
    }
  }
  function renamesRadiosPlugin(node) {
    if (node.props.type === "radio") {
      node.addProps(["altName"]);
      node.props.altName = `${node.name}_${radioInstance++}`;
    }
  }
  function normalizeBoxes(node) {
    return function(prop, next) {
      if (prop.prop === "options" && Array.isArray(prop.value)) {
        prop.value = prop.value.map((option2) => {
          if (!option2.attrs?.id) {
            return extend(option2, {
              attrs: {
                id: `${node.props.id}-option-${slugify(String(option2.value))}`
              }
            });
          }
          return option2;
        });
        if (node.props.type === "checkbox" && !Array.isArray(node.value)) {
          if (node.isCreated) {
            node.input([], false);
          } else {
            node.on("created", () => {
              if (!Array.isArray(node.value)) {
                node.input([], false);
              }
            });
          }
        }
      }
      return next(prop);
    };
  }
  function toggleChecked(node, e) {
    const el = e.target;
    if (el instanceof HTMLInputElement) {
      const value = Array.isArray(node.props.options) ? optionValue(node.props.options, el.value) : el.value;
      if (Array.isArray(node.props.options) && node.props.options.length) {
        if (!Array.isArray(node._value)) {
          node.input([value]);
        } else if (!node._value.some((existingValue) => shouldSelect(value, existingValue))) {
          node.input([...node._value, value]);
        } else {
          node.input(
            node._value.filter(
              (existingValue) => !shouldSelect(value, existingValue)
            )
          );
        }
      } else {
        if (el.checked) {
          node.input(node.props.onValue);
        } else {
          node.input(node.props.offValue);
        }
      }
    }
  }
  function isChecked(node, value) {
    node.context?.value;
    node.context?._value;
    if (Array.isArray(node._value)) {
      return node._value.some(
        (existingValue) => shouldSelect(optionValue(node.props.options, value), existingValue)
      );
    }
    return false;
  }
  function checkboxes(node) {
    node.on("created", () => {
      if (node.context?.handlers) {
        node.context.handlers.toggleChecked = toggleChecked.bind(null, node);
      }
      if (node.context?.fns) {
        node.context.fns.isChecked = isChecked.bind(null, node);
      }
      if (!has(node.props, "onValue"))
        node.props.onValue = true;
      if (!has(node.props, "offValue"))
        node.props.offValue = false;
    });
    node.hook.prop(normalizeBoxes(node));
  }
  function defaultIcon(sectionKey, defaultIcon2) {
    return (node) => {
      if (node.props[`${sectionKey}Icon`] === void 0) {
        node.props[`${sectionKey}Icon`] = defaultIcon2.startsWith("<svg") ? defaultIcon2 : `default:${defaultIcon2}`;
      }
    };
  }
  function disables(node) {
    node.on("created", () => {
      if ("disabled" in node.props) {
        node.props.disabled = undefine(node.props.disabled);
        node.config.disabled = undefine(node.props.disabled);
      }
    });
    node.hook.prop(({ prop, value }, next) => {
      value = prop === "disabled" ? undefine(value) : value;
      return next({ prop, value });
    });
    node.on("prop:disabled", ({ payload: value }) => {
      node.config.disabled = undefine(value);
    });
  }
  function localize(key, value) {
    return (node) => {
      node.store.set(
        /* @__PURE__ */ createMessage({
          key,
          type: "ui",
          value: value || key,
          meta: {
            localize: true,
            i18nArgs: [node]
          }
        })
      );
    };
  }
  function removeHover(e) {
    if (e.target instanceof HTMLElement && e.target.hasAttribute("data-file-hover")) {
      e.target.removeAttribute("data-file-hover");
    }
  }
  function preventStrayDrop(type, e) {
    if (!(e.target instanceof HTMLInputElement)) {
      e.preventDefault();
    } else if (type === "dragover") {
      e.target.setAttribute("data-file-hover", "true");
    }
    if (type === "drop") {
      removeHover(e);
    }
  }
  function files(node) {
    localize("noFiles", "Select file")(node);
    localize("removeAll", "Remove all")(node);
    localize("remove")(node);
    node.addProps(["_hasMultipleFiles"]);
    if (isBrowser) {
      if (!window._FormKit_File_Drop) {
        window.addEventListener(
          "dragover",
          preventStrayDrop.bind(null, "dragover")
        );
        window.addEventListener("drop", preventStrayDrop.bind(null, "drop"));
        window.addEventListener("dragleave", removeHover);
        window._FormKit_File_Drop = true;
      }
    }
    node.hook.input((value, next) => next(Array.isArray(value) ? value : []));
    node.on("input", ({ payload: value }) => {
      node.props._hasMultipleFiles = Array.isArray(value) && value.length > 1 ? true : void 0;
    });
    node.on("reset", () => {
      if (node.props.id && isBrowser) {
        const el = document.getElementById(node.props.id);
        if (el)
          el.value = "";
      }
    });
    node.on("created", () => {
      if (!Array.isArray(node.value))
        node.input([], false);
      if (!node.context)
        return;
      node.context.handlers.resetFiles = (e) => {
        e.preventDefault();
        node.input([]);
        if (node.props.id && isBrowser) {
          const el = document.getElementById(node.props.id);
          if (el)
            el.value = "";
          el?.focus();
        }
      };
      node.context.handlers.files = (e) => {
        const files2 = [];
        if (e.target instanceof HTMLInputElement && e.target.files) {
          for (let i = 0; i < e.target.files.length; i++) {
            let file2;
            if (file2 = e.target.files.item(i)) {
              files2.push({ name: file2.name, file: file2 });
            }
          }
          node.input(files2);
        }
        if (node.context)
          node.context.files = files2;
        if (typeof node.props.attrs?.onChange === "function") {
          node.props.attrs?.onChange(e);
        }
      };
    });
  }
  async function handleSubmit(node, submitEvent) {
    const submitNonce = Math.random();
    node.props._submitNonce = submitNonce;
    submitEvent.preventDefault();
    await node.settled;
    if (node.ledger.value("validating")) {
      node.store.set(loading);
      await node.ledger.settled("validating");
      node.store.remove("loading");
      if (node.props._submitNonce !== submitNonce)
        return;
    }
    const setSubmitted = (n) => n.store.set(
      /* @__PURE__ */ createMessage({
        key: "submitted",
        value: true,
        visible: false
      })
    );
    node.walk(setSubmitted);
    setSubmitted(node);
    node.emit("submit-raw");
    if (typeof node.props.onSubmitRaw === "function") {
      node.props.onSubmitRaw(submitEvent, node);
    }
    if (node.ledger.value("blocking")) {
      if (typeof node.props.onSubmitInvalid === "function") {
        node.props.onSubmitInvalid(node);
      }
      if (node.props.incompleteMessage !== false) {
        setIncompleteMessage(node);
      }
    } else {
      if (typeof node.props.onSubmit === "function") {
        const retVal = node.props.onSubmit(
          node.hook.submit.dispatch(clone(node.value)),
          node
        );
        if (retVal instanceof Promise) {
          const autoDisable = node.props.disabled === void 0 && node.props.submitBehavior !== "live";
          if (autoDisable)
            node.props.disabled = true;
          node.store.set(loading);
          await retVal;
          if (autoDisable)
            node.props.disabled = false;
          node.store.remove("loading");
        }
      } else {
        if (submitEvent.target instanceof HTMLFormElement) {
          submitEvent.target.submit();
        }
      }
    }
  }
  function setIncompleteMessage(node) {
    node.store.set(
      /* @__PURE__ */ createMessage({
        blocking: false,
        key: `incomplete`,
        meta: {
          localize: node.props.incompleteMessage === void 0,
          i18nArgs: [{ node }],
          showAsMessage: true
        },
        type: "ui",
        value: node.props.incompleteMessage || "Form incomplete."
      })
    );
  }
  function form(node) {
    var _a;
    node.props.isForm = true;
    node.ledger.count("validating", (m) => m.key === "validating");
    (_a = node.props).submitAttrs ?? (_a.submitAttrs = {
      disabled: node.props.disabled
    });
    node.on("prop:disabled", ({ payload: disabled }) => {
      node.props.submitAttrs = { ...node.props.submitAttrs, disabled };
    });
    node.on("created", () => {
      if (node.context?.handlers) {
        node.context.handlers.submit = handleSubmit.bind(null, node);
      }
      if (!has(node.props, "actions")) {
        node.props.actions = true;
      }
    });
    node.on("prop:incompleteMessage", () => {
      if (node.store.incomplete)
        setIncompleteMessage(node);
    });
    node.on("settled:blocking", () => node.store.remove("incomplete"));
  }
  function ignore(node) {
    if (node.props.ignore === void 0) {
      node.props.ignore = true;
      node.parent = null;
    }
  }
  function initialValue(node) {
    node.on("created", () => {
      if (node.context) {
        node.context.initialValue = node.value || "";
      }
    });
  }
  function casts(node) {
    if (typeof node.props.number === "undefined")
      return;
    const strict = ["number", "range", "hidden"].includes(node.props.type);
    node.hook.input((value, next) => {
      if (value === "")
        return next(void 0);
      const numericValue = node.props.number === "integer" ? parseInt(value) : parseFloat(value);
      if (!Number.isFinite(numericValue))
        return strict ? next(void 0) : next(value);
      return next(numericValue);
    });
  }
  function toggleChecked2(node, event) {
    if (event.target instanceof HTMLInputElement) {
      node.input(optionValue(node.props.options, event.target.value));
    }
  }
  function isChecked2(node, value) {
    node.context?.value;
    node.context?._value;
    return shouldSelect(optionValue(node.props.options, value), node._value);
  }
  function radios(node) {
    node.on("created", () => {
      if (!Array.isArray(node.props.options)) {
        warn(350, {
          node,
          inputType: "radio"
        });
      }
      if (node.context?.handlers) {
        node.context.handlers.toggleChecked = toggleChecked2.bind(null, node);
      }
      if (node.context?.fns) {
        node.context.fns.isChecked = isChecked2.bind(null, node);
      }
    });
    node.hook.prop(normalizeBoxes(node));
  }
  function isSelected(node, option2) {
    if (isGroupOption(option2))
      return false;
    node.context && node.context.value;
    const optionValue2 = "__original" in option2 ? option2.__original : option2.value;
    return Array.isArray(node._value) ? node._value.some((optionA) => shouldSelect(optionA, optionValue2)) : (node._value === void 0 || node._value === null && !containsValue(node.props.options, null)) && option2.attrs && option2.attrs["data-is-placeholder"] ? true : shouldSelect(optionValue2, node._value);
  }
  function containsValue(options2, value) {
    return options2.some((option2) => {
      if (isGroupOption(option2)) {
        return containsValue(option2.options, value);
      } else {
        return ("__original" in option2 ? option2.__original : option2.value) === value;
      }
    });
  }
  async function deferChange(node, e) {
    if (typeof node.props.attrs?.onChange === "function") {
      await new Promise((r) => setTimeout(r, 0));
      await node.settled;
      node.props.attrs.onChange(e);
    }
  }
  function selectInput2(node, e) {
    const target = e.target;
    const value = target.hasAttribute("multiple") ? Array.from(target.selectedOptions).map(
      (o) => optionValue(node.props.options, o.value)
    ) : optionValue(node.props.options, target.value);
    node.input(value);
  }
  function applyPlaceholder(options2, placeholder) {
    if (!options2.some(
      (option2) => option2.attrs && option2.attrs["data-is-placeholder"]
    )) {
      return [
        {
          label: placeholder,
          value: "",
          attrs: {
            hidden: true,
            disabled: true,
            "data-is-placeholder": "true"
          }
        },
        ...options2
      ];
    }
    return options2;
  }
  function firstValue(options2) {
    const option2 = options2.length > 0 ? options2[0] : void 0;
    if (!option2)
      return void 0;
    if (isGroupOption(option2))
      return firstValue(option2.options);
    return "__original" in option2 ? option2.__original : option2.value;
  }
  function select2(node) {
    node.on("created", () => {
      const isMultiple = undefine(node.props.attrs?.multiple);
      if (!isMultiple && node.props.placeholder && Array.isArray(node.props.options)) {
        node.hook.prop(({ prop, value }, next) => {
          if (prop === "options") {
            value = applyPlaceholder(value, node.props.placeholder);
          }
          return next({ prop, value });
        });
        node.props.options = applyPlaceholder(
          node.props.options,
          node.props.placeholder
        );
      }
      if (isMultiple) {
        if (node.value === void 0) {
          node.input([], false);
        }
      } else if (node.context && !node.context.options) {
        node.props.attrs = Object.assign({}, node.props.attrs, {
          value: node._value
        });
        node.on("input", ({ payload }) => {
          node.props.attrs = Object.assign({}, node.props.attrs, {
            value: payload
          });
        });
      }
      if (node.context?.handlers) {
        node.context.handlers.selectInput = selectInput2.bind(null, node);
        node.context.handlers.onChange = deferChange.bind(null, node);
      }
      if (node.context?.fns) {
        node.context.fns.isSelected = isSelected.bind(null, node);
        node.context.fns.showPlaceholder = (value, placeholder) => {
          if (!Array.isArray(node.props.options))
            return false;
          const hasMatchingValue = node.props.options.some(
            (option2) => {
              if (option2.attrs && "data-is-placeholder" in option2.attrs)
                return false;
              const optionValue2 = "__original" in option2 ? option2.__original : option2.value;
              return eq(value, optionValue2);
            }
          );
          return placeholder && !hasMatchingValue ? true : void 0;
        };
      }
    });
    node.hook.input((value, next) => {
      if (!node.props.placeholder && value === void 0 && Array.isArray(node.props?.options) && node.props.options.length && !undefine(node.props?.attrs?.multiple)) {
        value = firstValue(node.props.options);
      }
      return next(value);
    });
  }
  // @__NO_SIDE_EFFECTS__
  function isSlotCondition(node) {
    if (isConditional(node) && node.if && node.if.startsWith("$slots.") && typeof node.then === "string" && node.then.startsWith("$slots.") && "else" in node) {
      return true;
    }
    return false;
  }
  // @__NO_SIDE_EFFECTS__
  function useSchema(inputSection, sectionsSchema = {}) {
    const schema = /* @__PURE__ */ outer(
      /* @__PURE__ */ wrapper(
        /* @__PURE__ */ label("$label"),
        /* @__PURE__ */ inner(/* @__PURE__ */ icon("prefix"), /* @__PURE__ */ prefix(), inputSection(), /* @__PURE__ */ suffix(), /* @__PURE__ */ icon("suffix"))
      ),
      /* @__PURE__ */ help("$help"),
      /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
    );
    return (propSectionsSchema = {}) => schema(extend(sectionsSchema, propSectionsSchema));
  }
  // @__NO_SIDE_EFFECTS__
  function $if(condition, then, otherwise) {
    const extendable = (extensions) => {
      const node = then(extensions);
      if (otherwise || isSchemaObject(node) && "if" in node || /* @__PURE__ */ isSlotCondition(node)) {
        const conditionalNode = {
          if: condition,
          then: node
        };
        if (otherwise) {
          conditionalNode.else = otherwise(extensions);
        }
        return conditionalNode;
      } else if (/* @__PURE__ */ isSlotCondition(node)) {
        Object.assign(node.else, { if: condition });
      } else if (isSchemaObject(node)) {
        Object.assign(node, { if: condition });
      }
      return node;
    };
    extendable._s = token();
    return extendable;
  }
  // @__NO_SIDE_EFFECTS__
  function $extend(section, extendWith) {
    const extendable = (extensions) => {
      const node = section({});
      if (/* @__PURE__ */ isSlotCondition(node)) {
        if (Array.isArray(node.else))
          return node;
        node.else = /* @__PURE__ */ extendSchema(
          /* @__PURE__ */ extendSchema(node.else, extendWith),
          section._s ? extensions[section._s] : {}
        );
        return node;
      }
      return /* @__PURE__ */ extendSchema(
        /* @__PURE__ */ extendSchema(node, extendWith),
        section._s ? extensions[section._s] : {}
      );
    };
    extendable._s = section._s;
    return extendable;
  }
  function resetCounts() {
    resetRadio();
  }
  var runtimeProps, actions, box, boxHelp, boxInner, boxLabel, boxOption, boxOptions, boxWrapper, buttonInput, buttonLabel, decorator, fieldset, fileInput, fileItem, fileList, fileName, fileRemove, formInput, fragment, help, icon, inner, label, legend, message, messages, noFiles, optGroup, option, optionSlot, outer, prefix, selectInput, submitInput, suffix, textInput, textareaInput, wrapper, radioInstance, isBrowser, loading, button, checkbox, file, form2, group, hidden, list, meta, radio, select22, textarea, text2, inputs;
  var init_dist3 = __esm({
    "packages/inputs/dist/index.mjs"() {
      init_dist();
      init_dist2();
      runtimeProps = [
        "classes",
        "config",
        "delay",
        "errors",
        "id",
        "index",
        "inputErrors",
        "library",
        "modelValue",
        "onUpdate:modelValue",
        "name",
        "number",
        "parent",
        "plugins",
        "sectionsSchema",
        "type",
        "validation",
        "validationLabel",
        "validationMessages",
        "validationRules",
        // Runtime event props:
        "onInput",
        "onInputRaw",
        "onUpdate:modelValue",
        "onNode",
        "onSubmit",
        "onSubmitInvalid",
        "onSubmitRaw"
      ];
      actions = /* @__PURE__ */ createSection("actions", () => ({
        $el: "div",
        if: "$actions"
      }));
      box = /* @__PURE__ */ createSection("input", () => ({
        $el: "input",
        bind: "$attrs",
        attrs: {
          type: "$type",
          name: "$node.props.altName || $node.name",
          disabled: "$option.attrs.disabled || $disabled",
          onInput: "$handlers.toggleChecked",
          checked: "$fns.eq($_value, $onValue)",
          onBlur: "$handlers.blur",
          value: "$: true",
          id: "$id",
          "aria-describedby": {
            if: "$options.length",
            then: {
              if: "$option.help",
              then: '$: "help-" + $option.attrs.id',
              else: void 0
            },
            else: {
              if: "$help",
              then: '$: "help-" + $id',
              else: void 0
            }
          }
        }
      }));
      boxHelp = /* @__PURE__ */ createSection("optionHelp", () => ({
        $el: "div",
        if: "$option.help",
        attrs: {
          id: '$: "help-" + $option.attrs.id'
        }
      }));
      boxInner = /* @__PURE__ */ createSection("inner", "span");
      boxLabel = /* @__PURE__ */ createSection("label", "span");
      boxOption = /* @__PURE__ */ createSection("option", () => ({
        $el: "li",
        for: ["option", "$options"],
        attrs: {
          "data-disabled": "$option.attrs.disabled || $disabled || undefined"
        }
      }));
      boxOptions = /* @__PURE__ */ createSection("options", "ul");
      boxWrapper = /* @__PURE__ */ createSection("wrapper", () => ({
        $el: "label",
        attrs: {
          "data-disabled": {
            if: "$options.length",
            then: void 0,
            else: "$disabled || undefined"
          },
          "data-checked": {
            if: "$options == undefined",
            then: "$fns.eq($_value, $onValue) || undefined",
            else: "$fns.isChecked($option.value) || undefined"
          }
        }
      }));
      buttonInput = /* @__PURE__ */ createSection("input", () => ({
        $el: "button",
        bind: "$attrs",
        attrs: {
          type: "$type",
          disabled: "$disabled",
          name: "$node.name",
          id: "$id"
        }
      }));
      buttonLabel = /* @__PURE__ */ createSection("default", null);
      decorator = /* @__PURE__ */ createSection("decorator", () => ({
        $el: "span",
        attrs: {
          "aria-hidden": "true"
        }
      }));
      fieldset = /* @__PURE__ */ createSection("fieldset", () => ({
        $el: "fieldset",
        attrs: {
          id: "$id",
          "aria-describedby": {
            if: "$help",
            then: '$: "help-" + $id',
            else: void 0
          }
        }
      }));
      fileInput = /* @__PURE__ */ createSection("input", () => ({
        $el: "input",
        bind: "$attrs",
        attrs: {
          type: "file",
          disabled: "$disabled",
          name: "$node.name",
          onChange: "$handlers.files",
          onBlur: "$handlers.blur",
          id: "$id",
          "aria-describedby": "$describedBy",
          "aria-required": "$state.required || undefined"
        }
      }));
      fileItem = /* @__PURE__ */ createSection("fileItem", () => ({
        $el: "li",
        for: ["file", "$value"]
      }));
      fileList = /* @__PURE__ */ createSection("fileList", () => ({
        $el: "ul",
        if: "$value.length",
        attrs: {
          "data-has-multiple": "$_hasMultipleFiles"
        }
      }));
      fileName = /* @__PURE__ */ createSection("fileName", () => ({
        $el: "span",
        attrs: {
          class: "$classes.fileName"
        }
      }));
      fileRemove = /* @__PURE__ */ createSection("fileRemove", () => ({
        $el: "button",
        attrs: {
          type: "button",
          onClick: "$handlers.resetFiles"
        }
      }));
      formInput = /* @__PURE__ */ createSection("form", () => ({
        $el: "form",
        bind: "$attrs",
        meta: {
          autoAnimate: true
        },
        attrs: {
          id: "$id",
          name: "$node.name",
          onSubmit: "$handlers.submit",
          "data-loading": "$state.loading || undefined"
        }
      }));
      fragment = /* @__PURE__ */ createSection("wrapper", null, true);
      help = /* @__PURE__ */ createSection("help", () => ({
        $el: "div",
        if: "$help",
        attrs: {
          id: '$: "help-" + $id'
        }
      }));
      icon = (sectionKey, el) => {
        return (/* @__PURE__ */ createSection(`${sectionKey}Icon`, () => {
          const rawIconProp = `_raw${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}Icon`;
          return {
            if: `$${sectionKey}Icon && $${rawIconProp}`,
            $el: `${el ? el : "span"}`,
            attrs: {
              class: `$classes.${sectionKey}Icon + " " + $classes.icon`,
              innerHTML: `$${rawIconProp}`,
              onClick: `$handlers.iconClick(${sectionKey})`,
              role: `$fns.iconRole(${sectionKey})`,
              tabindex: `$fns.iconRole(${sectionKey}) === "button" && "0" || undefined`,
              for: {
                if: `${el === "label"}`,
                then: "$id"
              }
            }
          };
        }))();
      };
      inner = /* @__PURE__ */ createSection("inner", "div");
      label = /* @__PURE__ */ createSection("label", () => ({
        $el: "label",
        if: "$label",
        attrs: {
          for: "$id"
        }
      }));
      legend = /* @__PURE__ */ createSection("legend", () => ({
        $el: "legend",
        if: "$label"
      }));
      message = /* @__PURE__ */ createSection("message", () => ({
        $el: "li",
        for: ["message", "$messages"],
        attrs: {
          key: "$message.key",
          id: `$id + '-' + $message.key`,
          "data-message-type": "$message.type"
        }
      }));
      messages = /* @__PURE__ */ createSection("messages", () => ({
        $el: "ul",
        if: "$defaultMessagePlacement && $fns.length($messages)"
      }));
      noFiles = /* @__PURE__ */ createSection("noFiles", () => ({
        $el: "span",
        if: "$value == null || $value.length == 0"
      }));
      optGroup = /* @__PURE__ */ createSection("optGroup", () => ({
        $el: "optgroup",
        bind: "$option.attrs",
        attrs: {
          label: "$option.group"
        }
      }));
      option = /* @__PURE__ */ createSection("option", () => ({
        $el: "option",
        bind: "$option.attrs",
        attrs: {
          class: "$classes.option",
          value: "$option.value",
          selected: "$fns.isSelected($option)"
        }
      }));
      optionSlot = /* @__PURE__ */ createSection("options", () => ({
        $el: null,
        if: "$options.length",
        for: ["option", "$option.options || $options"]
      }));
      outer = /* @__PURE__ */ createSection("outer", () => ({
        $el: "div",
        meta: {
          autoAnimate: true
        },
        attrs: {
          key: "$id",
          "data-family": "$family || undefined",
          "data-type": "$type",
          "data-multiple": '$attrs.multiple || ($type != "select" && $options != undefined) || undefined',
          "data-has-multiple": "$_hasMultipleFiles",
          "data-disabled": '$: ($disabled !== "false" && $disabled) || undefined',
          "data-empty": "$state.empty || undefined",
          "data-complete": "$state.complete || undefined",
          "data-invalid": "$state.invalid || undefined",
          "data-errors": "$state.errors || undefined",
          "data-submitted": "$state.submitted || undefined",
          "data-prefix-icon": "$_rawPrefixIcon !== undefined || undefined",
          "data-suffix-icon": "$_rawSuffixIcon !== undefined || undefined",
          "data-prefix-icon-click": "$onPrefixIconClick !== undefined || undefined",
          "data-suffix-icon-click": "$onSuffixIconClick !== undefined || undefined"
        }
      }));
      prefix = /* @__PURE__ */ createSection("prefix", null);
      selectInput = /* @__PURE__ */ createSection("input", () => ({
        $el: "select",
        bind: "$attrs",
        attrs: {
          id: "$id",
          "data-placeholder": "$fns.showPlaceholder($_value, $placeholder)",
          disabled: "$disabled",
          class: "$classes.input",
          name: "$node.name",
          onChange: "$handlers.onChange",
          onInput: "$handlers.selectInput",
          onBlur: "$handlers.blur",
          "aria-describedby": "$describedBy",
          "aria-required": "$state.required || undefined"
        }
      }));
      submitInput = /* @__PURE__ */ createSection("submit", () => ({
        $cmp: "FormKit",
        bind: "$submitAttrs",
        props: {
          type: "submit",
          label: "$submitLabel"
        }
      }));
      suffix = /* @__PURE__ */ createSection("suffix", null);
      textInput = /* @__PURE__ */ createSection("input", () => ({
        $el: "input",
        bind: "$attrs",
        attrs: {
          type: "$type",
          disabled: "$disabled",
          name: "$node.name",
          onInput: "$handlers.DOMInput",
          onBlur: "$handlers.blur",
          value: "$_value",
          id: "$id",
          "aria-describedby": "$describedBy",
          "aria-required": "$state.required || undefined"
        }
      }));
      textareaInput = /* @__PURE__ */ createSection("input", () => ({
        $el: "textarea",
        bind: "$attrs",
        attrs: {
          disabled: "$disabled",
          name: "$node.name",
          onInput: "$handlers.DOMInput",
          onBlur: "$handlers.blur",
          value: "$_value",
          id: "$id",
          "aria-describedby": "$describedBy",
          "aria-required": "$state.required || undefined"
        },
        children: "$initialValue"
      }));
      wrapper = /* @__PURE__ */ createSection("wrapper", "div");
      radioInstance = 0;
      isBrowser = typeof window !== "undefined";
      loading = /* @__PURE__ */ createMessage({
        key: "loading",
        value: true,
        visible: false
      });
      button = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value")),
          /* @__PURE__ */ wrapper(
            /* @__PURE__ */ buttonInput(
              /* @__PURE__ */ icon("prefix"),
              /* @__PURE__ */ prefix(),
              /* @__PURE__ */ buttonLabel("$label || $ui.submit.value"),
              /* @__PURE__ */ suffix(),
              /* @__PURE__ */ icon("suffix")
            )
          ),
          /* @__PURE__ */ help("$help")
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * The family of inputs this one belongs too. For example "text" and "email"
         * are both part of the "text" family. This is primary used for styling.
         */
        family: "button",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [localize("submit"), ignore],
        /**
         * A key to use for memoizing the schema. This is used to prevent the schema
         * from needing to be stringified when performing a memo lookup.
         */
        schemaMemoKey: "h6st4epl3j8"
      };
      checkbox = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ $if(
            "$options == undefined",
            /**
             * Single checkbox structure.
             */
            /* @__PURE__ */ boxWrapper(
              /* @__PURE__ */ boxInner(/* @__PURE__ */ prefix(), /* @__PURE__ */ box(), /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")), /* @__PURE__ */ suffix()),
              /* @__PURE__ */ $extend(/* @__PURE__ */ boxLabel("$label"), {
                if: "$label"
              })
            ),
            /**
             * Multi checkbox structure.
             */
            /* @__PURE__ */ fieldset(
              /* @__PURE__ */ legend("$label"),
              /* @__PURE__ */ help("$help"),
              /* @__PURE__ */ boxOptions(
                /* @__PURE__ */ boxOption(
                  /* @__PURE__ */ boxWrapper(
                    /* @__PURE__ */ boxInner(
                      /* @__PURE__ */ prefix(),
                      /* @__PURE__ */ $extend(/* @__PURE__ */ box(), {
                        bind: "$option.attrs",
                        attrs: {
                          id: "$option.attrs.id",
                          value: "$option.value",
                          checked: "$fns.isChecked($option.value)"
                        }
                      }),
                      /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")),
                      /* @__PURE__ */ suffix()
                    ),
                    /* @__PURE__ */ $extend(/* @__PURE__ */ boxLabel("$option.label"), {
                      if: "$option.label"
                    })
                  ),
                  /* @__PURE__ */ boxHelp("$option.help")
                )
              )
            )
          ),
          // Help text only goes under the input when it is a single.
          /* @__PURE__ */ $if("$options == undefined && $help", /* @__PURE__ */ help("$help")),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * The family of inputs this one belongs too. For example "text" and "email"
         * are both part of the "text" family. This is primary used for styling.
         */
        family: "box",
        /**
         * An array of extra props to accept for this input.
         */
        props: ["options", "onValue", "offValue", "optionsLoader"],
        /**
         * Additional features that should be added to your input
         */
        features: [
          options,
          checkboxes,
          defaultIcon("decorator", "checkboxDecorator")
        ],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "qje02tb3gu8"
      };
      file = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ wrapper(
            /* @__PURE__ */ label("$label"),
            /* @__PURE__ */ inner(
              /* @__PURE__ */ icon("prefix", "label"),
              /* @__PURE__ */ prefix(),
              /* @__PURE__ */ fileInput(),
              /* @__PURE__ */ fileList(
                /* @__PURE__ */ fileItem(
                  /* @__PURE__ */ icon("fileItem"),
                  /* @__PURE__ */ fileName("$file.name"),
                  /* @__PURE__ */ $if(
                    "$value.length === 1",
                    /* @__PURE__ */ fileRemove(
                      /* @__PURE__ */ icon("fileRemove"),
                      '$ui.remove.value + " " + $file.name'
                    )
                  )
                )
              ),
              /* @__PURE__ */ $if("$value.length > 1", /* @__PURE__ */ fileRemove("$ui.removeAll.value")),
              /* @__PURE__ */ noFiles(/* @__PURE__ */ icon("noFiles"), "$ui.noFiles.value"),
              /* @__PURE__ */ suffix(),
              /* @__PURE__ */ icon("suffix")
            )
          ),
          /* @__PURE__ */ help("$help"),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * The family of inputs this one belongs too. For example "text" and "email"
         * are both part of the "text" family. This is primary used for styling.
         */
        family: "text",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [
          files,
          defaultIcon("fileItem", "fileItem"),
          defaultIcon("fileRemove", "fileRemove"),
          defaultIcon("noFiles", "noFiles")
        ],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "9kqc4852fv8"
      };
      form2 = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ formInput(
          "$slots.default",
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value")),
          /* @__PURE__ */ actions(/* @__PURE__ */ submitInput())
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "group",
        /**
         * An array of extra props to accept for this input.
         */
        props: [
          "actions",
          "submit",
          "submitLabel",
          "submitAttrs",
          "submitBehavior",
          "incompleteMessage"
        ],
        /**
         * Additional features that should be added to your input
         */
        features: [form, disables],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "5bg016redjo"
      };
      group = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ fragment("$slots.default"),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "group",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [disables, renamesRadios]
      };
      hidden = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ textInput(),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [casts]
      };
      list = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ fragment("$slots.default"),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "list",
        /**
         * An array of extra props to accept for this input.
         */
        props: ["sync", "dynamic"],
        /**
         * Additional features that should be added to your input
         */
        features: [disables, renamesRadios]
      };
      meta = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ fragment(),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: []
      };
      radio = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ $if(
            "$options == undefined",
            /**
             * Single radio structure.
             */
            /* @__PURE__ */ boxWrapper(
              /* @__PURE__ */ boxInner(/* @__PURE__ */ prefix(), /* @__PURE__ */ box(), /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")), /* @__PURE__ */ suffix()),
              /* @__PURE__ */ $extend(/* @__PURE__ */ boxLabel("$label"), {
                if: "$label"
              })
            ),
            /**
             * Multi radio structure.
             */
            /* @__PURE__ */ fieldset(
              /* @__PURE__ */ legend("$label"),
              /* @__PURE__ */ help("$help"),
              /* @__PURE__ */ boxOptions(
                /* @__PURE__ */ boxOption(
                  /* @__PURE__ */ boxWrapper(
                    /* @__PURE__ */ boxInner(
                      /* @__PURE__ */ prefix(),
                      /* @__PURE__ */ $extend(/* @__PURE__ */ box(), {
                        bind: "$option.attrs",
                        attrs: {
                          id: "$option.attrs.id",
                          value: "$option.value",
                          checked: "$fns.isChecked($option.value)"
                        }
                      }),
                      /* @__PURE__ */ decorator(/* @__PURE__ */ icon("decorator")),
                      /* @__PURE__ */ suffix()
                    ),
                    /* @__PURE__ */ $extend(/* @__PURE__ */ boxLabel("$option.label"), {
                      if: "$option.label"
                    })
                  ),
                  /* @__PURE__ */ boxHelp("$option.help")
                )
              )
            )
          ),
          // Help text only goes under the input when it is a single.
          /* @__PURE__ */ $if("$options == undefined && $help", /* @__PURE__ */ help("$help")),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * The family of inputs this one belongs too. For example "text" and "email"
         * are both part of the "text" family. This is primary used for styling.
         */
        family: "box",
        /**
         * An array of extra props to accept for this input.
         */
        props: ["options", "onValue", "offValue", "optionsLoader"],
        /**
         * Additional features that should be added to your input
         */
        features: [options, radios, defaultIcon("decorator", "radioDecorator")],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "qje02tb3gu8"
      };
      select22 = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ wrapper(
            /* @__PURE__ */ label("$label"),
            /* @__PURE__ */ inner(
              /* @__PURE__ */ icon("prefix"),
              /* @__PURE__ */ prefix(),
              /* @__PURE__ */ selectInput(
                /* @__PURE__ */ $if(
                  "$slots.default",
                  () => "$slots.default",
                  /* @__PURE__ */ optionSlot(
                    /* @__PURE__ */ $if(
                      "$option.group",
                      /* @__PURE__ */ optGroup(/* @__PURE__ */ optionSlot(/* @__PURE__ */ option("$option.label"))),
                      /* @__PURE__ */ option("$option.label")
                    )
                  )
                )
              ),
              /* @__PURE__ */ $if("$attrs.multiple !== undefined", () => "", /* @__PURE__ */ icon("select")),
              /* @__PURE__ */ suffix(),
              /* @__PURE__ */ icon("suffix")
            )
          ),
          /* @__PURE__ */ help("$help"),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * An array of extra props to accept for this input.
         */
        props: ["options", "placeholder", "optionsLoader"],
        /**
         * Additional features that should be added to your input
         */
        features: [options, select2, defaultIcon("select", "select")],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "cb119h43krg"
      };
      textarea = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ wrapper(
            /* @__PURE__ */ label("$label"),
            /* @__PURE__ */ inner(
              /* @__PURE__ */ icon("prefix", "label"),
              /* @__PURE__ */ prefix(),
              /* @__PURE__ */ textareaInput(),
              /* @__PURE__ */ suffix(),
              /* @__PURE__ */ icon("suffix")
            )
          ),
          /* @__PURE__ */ help("$help"),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [initialValue],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "b1n0td79m9g"
      };
      text2 = {
        /**
         * The actual schema of the input, or a function that returns the schema.
         */
        schema: /* @__PURE__ */ outer(
          /* @__PURE__ */ wrapper(
            /* @__PURE__ */ label("$label"),
            /* @__PURE__ */ inner(
              /* @__PURE__ */ icon("prefix", "label"),
              /* @__PURE__ */ prefix(),
              /* @__PURE__ */ textInput(),
              /* @__PURE__ */ suffix(),
              /* @__PURE__ */ icon("suffix")
            )
          ),
          /* @__PURE__ */ help("$help"),
          /* @__PURE__ */ messages(/* @__PURE__ */ message("$message.value"))
        ),
        /**
         * The type of node, can be a list, group, or input.
         */
        type: "input",
        /**
         * The family of inputs this one belongs too. For example "text" and "email"
         * are both part of the "text" family. This is primary used for styling.
         */
        family: "text",
        /**
         * An array of extra props to accept for this input.
         */
        props: [],
        /**
         * Additional features that should be added to your input
         */
        features: [casts],
        /**
         * The key used to memoize the schema.
         */
        schemaMemoKey: "c3cc4kflsg"
      };
      inputs = {
        button,
        submit: button,
        checkbox,
        file,
        form: form2,
        group,
        hidden,
        list,
        meta,
        radio,
        select: select22,
        textarea,
        text: text2,
        color: text2,
        date: text2,
        datetimeLocal: text2,
        email: text2,
        month: text2,
        number: text2,
        password: text2,
        search: text2,
        tel: text2,
        time: text2,
        url: text2,
        week: text2,
        range: text2
      };
    }
  });

  // packages/rules/dist/index.mjs
  var dist_exports = {};
  __export(dist_exports, {
    accepted: () => accepted_default,
    alpha: () => alpha_default,
    alpha_spaces: () => alpha_spaces_default,
    alphanumeric: () => alphanumeric_default,
    between: () => between_default,
    confirm: () => confirm_default,
    contains_alpha: () => contains_alpha_default,
    contains_alpha_spaces: () => contains_alpha_spaces_default,
    contains_alphanumeric: () => contains_alphanumeric_default,
    contains_lowercase: () => contains_lowercase_default,
    contains_numeric: () => contains_numeric_default,
    contains_symbol: () => contains_symbol_default,
    contains_uppercase: () => contains_uppercase_default,
    date_after: () => date_after_default,
    date_after_node: () => date_after_node_default,
    date_after_or_equal: () => date_after_or_equal_default,
    date_before: () => date_before_default,
    date_before_node: () => date_before_node_default,
    date_before_or_equal: () => date_before_or_equal_default,
    date_between: () => date_between_default,
    date_format: () => date_format_default,
    email: () => email_default,
    ends_with: () => ends_with_default,
    is: () => is_default,
    length: () => length_default,
    lowercase: () => lowercase_default,
    matches: () => matches_default,
    max: () => max_default,
    min: () => min_default,
    not: () => not_default,
    number: () => number_default,
    require_one: () => require_one_default,
    required: () => required_default,
    starts_with: () => starts_with_default,
    symbol: () => symbol_default,
    uppercase: () => uppercase_default,
    url: () => url_default
  });
  var accepted, accepted_default, date_after, date_after_default, date_after_or_equal, date_after_or_equal_default, date_after_node, date_after_node_default, alpha, alpha_default, alpha_spaces, alpha_spaces_default, alphanumeric, alphanumeric_default, date_before, date_before_default, date_before_node, date_before_node_default, date_before_or_equal, date_before_or_equal_default, between, between_default, hasConfirm, confirm, confirm_default, contains_alpha, contains_alpha_default, contains_alpha_spaces, contains_alpha_spaces_default, contains_alphanumeric, contains_alphanumeric_default, contains_lowercase, contains_lowercase_default, contains_numeric, contains_numeric_default, contains_symbol, contains_symbol_default, contains_uppercase, contains_uppercase_default, date_between, date_between_default, date_format, date_format_default, email, email_default, ends_with, ends_with_default, is, is_default, length, length_default, lowercase, lowercase_default, matches, matches_default, max, max_default, min, min_default, not, not_default, number2, number_default, require_one, require_one_default, required, required_default, starts_with, starts_with_default, symbol, symbol_default, uppercase, uppercase_default, url, url_default;
  var init_dist4 = __esm({
    "packages/rules/dist/index.mjs"() {
      init_dist();
      accepted = function accepted2({ value }) {
        return ["yes", "on", "1", 1, true, "true"].includes(value);
      };
      accepted.skipEmpty = false;
      accepted_default = accepted;
      date_after = function({ value }, compare = false) {
        const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
        const fieldValue = Date.parse(String(value));
        return isNaN(fieldValue) ? false : fieldValue > timestamp;
      };
      date_after_default = date_after;
      date_after_or_equal = function({ value }, compare = false) {
        const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
        const fieldValue = Date.parse(String(value));
        return isNaN(fieldValue) ? false : fieldValue > timestamp || fieldValue === timestamp;
      };
      date_after_or_equal_default = date_after_or_equal;
      date_after_node = function(node, address) {
        if (!address)
          return false;
        const fieldValue = Date.parse(String(node.value));
        const foreignValue = Date.parse(String(node.at(address)?.value));
        if (isNaN(foreignValue))
          return true;
        return isNaN(fieldValue) ? false : fieldValue > foreignValue;
      };
      date_after_node_default = date_after_node;
      alpha = function({ value }, set = "default") {
        const sets = {
          default: /^\p{L}+$/u,
          latin: /^[a-z]+$/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      alpha_default = alpha;
      alpha_spaces = function({ value }, set = "default") {
        const sets = {
          default: /^[\p{L} ]+$/u,
          latin: /^[a-z ]+$/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      alpha_spaces_default = alpha_spaces;
      alphanumeric = function({ value }, set = "default") {
        const sets = {
          default: /^[0-9\p{L}]+$/u,
          latin: /^[0-9a-z]+$/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      alphanumeric_default = alphanumeric;
      date_before = function({ value }, compare = false) {
        const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
        const fieldValue = Date.parse(String(value));
        return isNaN(fieldValue) ? false : fieldValue < timestamp;
      };
      date_before_default = date_before;
      date_before_node = function(node, address) {
        if (!address)
          return false;
        const fieldValue = Date.parse(String(node.value));
        const foreignValue = Date.parse(String(node.at(address)?.value));
        if (isNaN(foreignValue))
          return true;
        return isNaN(fieldValue) ? false : fieldValue < foreignValue;
      };
      date_before_node_default = date_before_node;
      date_before_or_equal = function({ value }, compare = false) {
        const timestamp = Date.parse(compare || /* @__PURE__ */ new Date());
        const fieldValue = Date.parse(String(value));
        return isNaN(fieldValue) ? false : fieldValue < timestamp || fieldValue === timestamp;
      };
      date_before_or_equal_default = date_before_or_equal;
      between = function between2({ value }, from, to) {
        if (!isNaN(value) && !isNaN(from) && !isNaN(to)) {
          const val = 1 * value;
          from = Number(from);
          to = Number(to);
          const [a, b] = from <= to ? [from, to] : [to, from];
          return val >= 1 * a && val <= 1 * b;
        }
        return false;
      };
      between_default = between;
      hasConfirm = /(_confirm(?:ed)?)$/;
      confirm = function confirm2(node, address, comparison = "loose") {
        if (!address) {
          address = hasConfirm.test(node.name) ? node.name.replace(hasConfirm, "") : `${node.name}_confirm`;
        }
        const foreignValue = node.at(address)?.value;
        return comparison === "strict" ? node.value === foreignValue : node.value == foreignValue;
      };
      confirm_default = confirm;
      contains_alpha = function({ value }, set = "default") {
        const sets = {
          default: /\p{L}/u,
          latin: /[a-z]/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      contains_alpha_default = contains_alpha;
      contains_alpha_spaces = function({ value }, set = "default") {
        const sets = {
          default: /[\p{L} ]/u,
          latin: /[a-z ]/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      contains_alpha_spaces_default = contains_alpha_spaces;
      contains_alphanumeric = function({ value }, set = "default") {
        const sets = {
          default: /[0-9\p{L}]/u,
          latin: /[0-9a-z]/i
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      contains_alphanumeric_default = contains_alphanumeric;
      contains_lowercase = function({ value }, set = "default") {
        const sets = {
          default: /\p{Ll}/u,
          latin: /[a-z]/
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      contains_lowercase_default = contains_lowercase;
      contains_numeric = function number({ value }) {
        return /[0-9]/.test(String(value));
      };
      contains_numeric_default = contains_numeric;
      contains_symbol = function({ value }) {
        return /[!-/:-@[-`{-~]/.test(String(value));
      };
      contains_symbol_default = contains_symbol;
      contains_uppercase = function({ value }, set = "default") {
        const sets = {
          default: /\p{Lu}/u,
          latin: /[A-Z]/
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      contains_uppercase_default = contains_uppercase;
      date_between = function date_between2({ value }, dateA, dateB) {
        dateA = dateA instanceof Date ? dateA.getTime() : Date.parse(dateA);
        dateB = dateB instanceof Date ? dateB.getTime() : Date.parse(dateB);
        const compareTo = value instanceof Date ? value.getTime() : Date.parse(String(value));
        if (dateA && !dateB) {
          dateB = dateA;
          dateA = Date.now();
        } else if (!dateA || !compareTo) {
          return false;
        }
        return compareTo >= dateA && compareTo <= dateB;
      };
      date_between_default = date_between;
      date_format = function date({ value }, format) {
        if (format && typeof format === "string") {
          return regexForFormat(format).test(String(value));
        }
        return !isNaN(Date.parse(String(value)));
      };
      date_format_default = date_format;
      email = function email2({ value }) {
        const isEmail = /^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
        return isEmail.test(String(value));
      };
      email_default = email;
      ends_with = function ends_with2({ value }, ...stack) {
        if (typeof value === "string" && stack.length) {
          return stack.some((item) => {
            return value.endsWith(item);
          });
        } else if (typeof value === "string" && stack.length === 0) {
          return true;
        }
        return false;
      };
      ends_with_default = ends_with;
      is = function is2({ value }, ...stack) {
        return stack.some((item) => {
          if (typeof item === "object") {
            return eq(item, value);
          }
          return item == value;
        });
      };
      is_default = is;
      length = function length2({ value }, first = 0, second = Infinity) {
        first = parseInt(first);
        second = isNaN(parseInt(second)) ? Infinity : parseInt(second);
        const min3 = first <= second ? first : second;
        const max3 = second >= first ? second : first;
        if (typeof value === "string" || Array.isArray(value)) {
          return value.length >= min3 && value.length <= max3;
        } else if (value && typeof value === "object") {
          const length3 = Object.keys(value).length;
          return length3 >= min3 && length3 <= max3;
        }
        return false;
      };
      length_default = length;
      lowercase = function({ value }, set = "default") {
        const sets = {
          default: /^\p{Ll}+$/u,
          allow_non_alpha: /^[0-9\p{Ll}!-/:-@[-`{-~]+$/u,
          allow_numeric: /^[0-9\p{Ll}]+$/u,
          allow_numeric_dashes: /^[0-9\p{Ll}-]+$/u,
          latin: /^[a-z]+$/
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      lowercase_default = lowercase;
      matches = function matches2({ value }, ...stack) {
        return stack.some((pattern) => {
          if (typeof pattern === "string" && pattern.substr(0, 1) === "/" && pattern.substr(-1) === "/") {
            pattern = new RegExp(pattern.substr(1, pattern.length - 2));
          }
          if (pattern instanceof RegExp) {
            return pattern.test(String(value));
          }
          return pattern === value;
        });
      };
      matches_default = matches;
      max = function max2({ value }, maximum = 10) {
        if (Array.isArray(value)) {
          return value.length <= maximum;
        }
        return Number(value) <= Number(maximum);
      };
      max_default = max;
      min = function min2({ value }, minimum = 1) {
        if (Array.isArray(value)) {
          return value.length >= minimum;
        }
        return Number(value) >= Number(minimum);
      };
      min_default = min;
      not = function not2({ value }, ...stack) {
        return !stack.some((item) => {
          if (typeof item === "object") {
            return eq(item, value);
          }
          return item === value;
        });
      };
      not_default = not;
      number2 = function number3({ value }) {
        return !isNaN(value);
      };
      number_default = number2;
      require_one = function(node, ...inputNames) {
        if (!empty(node.value))
          return true;
        const values = inputNames.map((name) => node.at(name)?.value);
        return values.some((value) => !empty(value));
      };
      require_one.skipEmpty = false;
      require_one_default = require_one;
      required = function required2({ value }, action = "default") {
        return action === "trim" && typeof value === "string" ? !empty(value.trim()) : !empty(value);
      };
      required.skipEmpty = false;
      required_default = required;
      starts_with = function starts_with2({ value }, ...stack) {
        if (typeof value === "string" && stack.length) {
          return stack.some((item) => {
            return value.startsWith(item);
          });
        } else if (typeof value === "string" && stack.length === 0) {
          return true;
        }
        return false;
      };
      starts_with_default = starts_with;
      symbol = function({ value }) {
        return /^[!-/:-@[-`{-~]+$/.test(String(value));
      };
      symbol_default = symbol;
      uppercase = function({ value }, set = "default") {
        const sets = {
          default: /^\p{Lu}+$/u,
          latin: /^[A-Z]+$/
        };
        const selectedSet = has(sets, set) ? set : "default";
        return sets[selectedSet].test(String(value));
      };
      uppercase_default = uppercase;
      url = function url2({ value }, ...stack) {
        try {
          const protocols = stack.length ? stack : ["http:", "https:"];
          const url3 = new URL(String(value));
          return protocols.includes(url3.protocol);
        } catch {
          return false;
        }
      };
      url_default = url;
    }
  });

  // packages/observer/dist/index.mjs
  function createObserver(node, dependencies) {
    const deps = dependencies || Object.assign(/* @__PURE__ */ new Map(), { active: false });
    const receipts2 = /* @__PURE__ */ new Map();
    const addDependency = function(event) {
      if (!deps.active)
        return;
      if (!deps.has(node))
        deps.set(node, /* @__PURE__ */ new Set());
      deps.get(node)?.add(event);
    };
    const observeProps = function(props) {
      return new Proxy(props, {
        get(...args) {
          typeof args[1] === "string" && addDependency(`prop:${args[1]}`);
          return Reflect.get(...args);
        }
      });
    };
    const observeLedger = function(ledger) {
      return new Proxy(ledger, {
        get(...args) {
          if (args[1] === "value") {
            return (key) => {
              addDependency(`count:${key}`);
              return ledger.value(key);
            };
          }
          return Reflect.get(...args);
        }
      });
    };
    const observe = function(value, property) {
      if (isNode(value)) {
        return createObserver(value, deps);
      }
      if (property === "value")
        addDependency("commit");
      if (property === "_value")
        addDependency("input");
      if (property === "props")
        return observeProps(value);
      if (property === "ledger")
        return observeLedger(value);
      if (property === "children") {
        addDependency("child");
        addDependency("childRemoved");
      }
      return value;
    };
    const {
      proxy: observed,
      revoke
    } = Proxy.revocable(node, {
      get(...args) {
        switch (args[1]) {
          case "_node":
            return node;
          case "deps":
            return deps;
          case "watch":
            return (block, after, pos) => watch5(observed, block, after, pos);
          case "observe":
            return () => {
              const old = new Map(deps);
              deps.clear();
              deps.active = true;
              return old;
            };
          case "stopObserve":
            return () => {
              const newDeps = new Map(deps);
              deps.active = false;
              return newDeps;
            };
          case "receipts":
            return receipts2;
          case "kill":
            return () => {
              removeListeners(receipts2);
              revokedObservers.add(args[2]);
              revoke();
              return void 0;
            };
        }
        const value = Reflect.get(...args);
        if (typeof value === "function") {
          return (...subArgs) => {
            const subValue = value(...subArgs);
            return observe(subValue, args[1]);
          };
        }
        return observe(value, args[1]);
      }
    });
    return observed;
  }
  function applyListeners(node, [toAdd, toRemove], callback, pos) {
    toAdd.forEach((events, depNode) => {
      events.forEach((event) => {
        node.receipts.has(depNode) || node.receipts.set(depNode, {});
        const events2 = node.receipts.get(depNode) ?? {};
        events2[event] = events2[event] ?? [];
        events2[event].push(depNode.on(event, callback, pos));
        node.receipts.set(depNode, events2);
      });
    });
    toRemove.forEach((events, depNode) => {
      events.forEach((event) => {
        if (node.receipts.has(depNode)) {
          const nodeReceipts = node.receipts.get(depNode);
          if (nodeReceipts && has(nodeReceipts, event)) {
            nodeReceipts[event].map(depNode.off);
            delete nodeReceipts[event];
            node.receipts.set(depNode, nodeReceipts);
          }
        }
      });
    });
  }
  function removeListeners(receipts2) {
    receipts2.forEach((events, node) => {
      for (const event in events) {
        events[event].map(node.off);
      }
    });
    receipts2.clear();
  }
  function watch5(node, block, after, pos) {
    const doAfterObservation = (res2) => {
      const newDeps = node.stopObserve();
      applyListeners(
        node,
        diffDeps(oldDeps, newDeps),
        () => watch5(node, block, after, pos),
        pos
      );
      if (after)
        after(res2);
    };
    const oldDeps = new Map(node.deps);
    node.observe();
    const res = block(node);
    if (res instanceof Promise)
      res.then((val) => doAfterObservation(val));
    else
      doAfterObservation(res);
  }
  function diffDeps(previous, current) {
    const toAdd = /* @__PURE__ */ new Map();
    const toRemove = /* @__PURE__ */ new Map();
    current.forEach((events, node) => {
      if (!previous.has(node)) {
        toAdd.set(node, events);
      } else {
        const eventsToAdd = /* @__PURE__ */ new Set();
        const previousEvents = previous.get(node);
        events.forEach(
          (event) => !previousEvents?.has(event) && eventsToAdd.add(event)
        );
        toAdd.set(node, eventsToAdd);
      }
    });
    previous.forEach((events, node) => {
      if (!current.has(node)) {
        toRemove.set(node, events);
      } else {
        const eventsToRemove = /* @__PURE__ */ new Set();
        const newEvents = current.get(node);
        events.forEach(
          (event) => !newEvents?.has(event) && eventsToRemove.add(event)
        );
        toRemove.set(node, eventsToRemove);
      }
    });
    return [toAdd, toRemove];
  }
  function isKilled(node) {
    return revokedObservers.has(node);
  }
  var revokedObservers;
  var init_dist5 = __esm({
    "packages/observer/dist/index.mjs"() {
      init_dist();
      init_dist2();
      revokedObservers = /* @__PURE__ */ new WeakSet();
    }
  });

  // packages/validation/dist/index.mjs
  function createValidationPlugin(baseRules = {}) {
    return function validationPlugin(node) {
      let propRules = cloneAny(node.props.validationRules || {});
      let availableRules = { ...baseRules, ...propRules };
      const state = { input: token(), rerun: null, isPassing: true };
      let validation = cloneAny(node.props.validation);
      node.on("prop:validation", ({ payload }) => reboot(payload, propRules));
      node.on(
        "prop:validationRules",
        ({ payload }) => reboot(validation, payload)
      );
      function reboot(newValidation, newRules) {
        if (eq(Object.keys(propRules || {}), Object.keys(newRules || {})) && eq(validation, newValidation))
          return;
        propRules = cloneAny(newRules);
        validation = cloneAny(newValidation);
        availableRules = { ...baseRules, ...propRules };
        node.props.parsedRules?.forEach((validation2) => {
          removeMessage2(validation2);
          removeListeners(validation2.observer.receipts);
          validation2.observer.kill();
        });
        node.store.filter(() => false, "validation");
        node.props.parsedRules = parseRules(newValidation, availableRules, node);
        state.isPassing = true;
        validate(node, node.props.parsedRules, state);
      }
      node.props.parsedRules = parseRules(validation, availableRules, node);
      validate(node, node.props.parsedRules, state);
    };
  }
  function validate(node, validations, state) {
    if (isKilled(node))
      return;
    state.input = token();
    node.store.set(
      /* @__PURE__ */ createMessage({
        key: "failing",
        value: !state.isPassing,
        visible: false
      })
    );
    state.isPassing = true;
    node.store.filter((message4) => !message4.meta.removeImmediately, "validation");
    validations.forEach(
      (validation) => validation.debounce && clearTimeout(validation.timer)
    );
    if (validations.length) {
      node.store.set(validatingMessage);
      run(0, validations, state, false, () => {
        node.store.remove(validatingMessage.key);
        node.store.set(
          /* @__PURE__ */ createMessage({
            key: "failing",
            value: !state.isPassing,
            visible: false
          })
        );
      });
    }
  }
  function run(current, validations, state, removeImmediately, complete) {
    const validation = validations[current];
    if (!validation)
      return complete();
    const node = validation.observer;
    if (isKilled(node))
      return;
    const currentRun = state.input;
    validation.state = null;
    function next(async, result) {
      if (state.input !== currentRun)
        return;
      state.isPassing = state.isPassing && !!result;
      validation.queued = false;
      const newDeps = node.stopObserve();
      const diff = diffDeps(validation.deps, newDeps);
      applyListeners(
        node,
        diff,
        function revalidate() {
          try {
            node.store.set(validatingMessage);
          } catch (e) {
          }
          validation.queued = true;
          if (state.rerun)
            clearTimeout(state.rerun);
          state.rerun = setTimeout(
            validate,
            0,
            node,
            validations,
            state
          );
        },
        "unshift"
        // We want these listeners to run before other events are emitted so the 'state.validating' will be reliable.
      );
      validation.deps = newDeps;
      validation.state = result;
      if (result === false) {
        createFailedMessage(validation, removeImmediately || async);
      } else {
        removeMessage2(validation);
      }
      if (validations.length > current + 1) {
        const nextValidation = validations[current + 1];
        if ((result || nextValidation.force || !nextValidation.skipEmpty) && nextValidation.state === null) {
          nextValidation.queued = true;
        }
        run(current + 1, validations, state, removeImmediately || async, complete);
      } else {
        complete();
      }
    }
    if ((!empty(node.value) || !validation.skipEmpty) && (state.isPassing || validation.force)) {
      if (validation.queued) {
        runRule(validation, node, (result) => {
          result instanceof Promise ? result.then((r) => next(true, r)) : next(false, result);
        });
      } else {
        run(current + 1, validations, state, removeImmediately, complete);
      }
    } else if (empty(node.value) && validation.skipEmpty && state.isPassing) {
      node.observe();
      node.value;
      next(false, state.isPassing);
    } else {
      next(false, null);
    }
  }
  function runRule(validation, node, after) {
    if (validation.debounce) {
      validation.timer = setTimeout(() => {
        node.observe();
        after(validation.rule(node, ...validation.args));
      }, validation.debounce);
    } else {
      node.observe();
      after(validation.rule(node, ...validation.args));
    }
  }
  function removeMessage2(validation) {
    const key = `rule_${validation.name}`;
    if (validation.messageObserver) {
      validation.messageObserver = validation.messageObserver.kill();
    }
    if (has(validation.observer.store, key)) {
      validation.observer.store.remove(key);
    }
  }
  function createFailedMessage(validation, removeImmediately) {
    const node = validation.observer;
    if (isKilled(node))
      return;
    if (!validation.messageObserver) {
      validation.messageObserver = createObserver(node._node);
    }
    validation.messageObserver.watch(
      (node2) => {
        const i18nArgs = createI18nArgs(
          node2,
          validation
        );
        return i18nArgs;
      },
      (i18nArgs) => {
        const customMessage = createCustomMessage(node, validation, i18nArgs);
        const message4 = /* @__PURE__ */ createMessage({
          blocking: validation.blocking,
          key: `rule_${validation.name}`,
          meta: {
            /**
             * Use this key instead of the message root key to produce i18n validation
             * messages.
             */
            messageKey: validation.name,
            /**
             * For messages that were created *by or after* a debounced or async
             * validation rule — we make note of it so we can immediately remove them
             * as soon as the next commit happens.
             */
            removeImmediately,
            /**
             * Determines if this message should be passed to localization.
             */
            localize: !customMessage,
            /**
             * The arguments that will be passed to the validation rules
             */
            i18nArgs
          },
          type: "validation",
          value: customMessage || "This field is not valid."
        });
        node.store.set(message4);
      }
    );
  }
  function createCustomMessage(node, validation, i18nArgs) {
    const customMessage = node.props.validationMessages && has(node.props.validationMessages, validation.name) ? node.props.validationMessages[validation.name] : void 0;
    if (typeof customMessage === "function") {
      return customMessage(...i18nArgs);
    }
    return customMessage;
  }
  function createI18nArgs(node, validation) {
    return [
      {
        node,
        name: createMessageName(node),
        args: validation.args
      }
    ];
  }
  function createMessageName(node) {
    if (typeof node.props.validationLabel === "function") {
      return node.props.validationLabel(node);
    }
    return node.props.validationLabel || node.props.label || node.props.name || String(node.name);
  }
  function parseRules(validation, rules, node) {
    if (!validation)
      return [];
    const intents = typeof validation === "string" ? extractRules(validation) : clone(validation);
    return intents.reduce((validations, args) => {
      let rule = args.shift();
      const hints = {};
      if (typeof rule === "string") {
        const [ruleName, parsedHints] = parseHints(rule);
        if (has(rules, ruleName)) {
          rule = rules[ruleName];
          Object.assign(hints, parsedHints);
        }
      }
      if (typeof rule === "function") {
        validations.push({
          observer: createObserver(node),
          rule,
          args,
          timer: 0,
          state: null,
          queued: true,
          deps: /* @__PURE__ */ new Map(),
          ...defaultHints,
          ...fnHints(hints, rule)
        });
      }
      return validations;
    }, []);
  }
  function extractRules(validation) {
    return validation.split("|").reduce((rules, rule) => {
      const parsedRule = parseRule(rule);
      if (parsedRule) {
        rules.push(parsedRule);
      }
      return rules;
    }, []);
  }
  function parseRule(rule) {
    const trimmed = rule.trim();
    if (trimmed) {
      const matches3 = trimmed.match(ruleExtractor);
      if (matches3 && typeof matches3[1] === "string") {
        const ruleName = matches3[1].trim();
        const args = matches3[2] && typeof matches3[2] === "string" ? matches3[2].split(",").map((s) => s.trim()) : [];
        return [ruleName, ...args];
      }
    }
    return false;
  }
  function parseHints(ruleName) {
    const matches3 = ruleName.match(hintExtractor);
    if (!matches3) {
      return [ruleName, { name: ruleName }];
    }
    const map = {
      "*": { force: true },
      "+": { skipEmpty: false },
      "?": { blocking: false }
    };
    const [, hints, rule] = matches3;
    const hintGroups = hasDebounce.test(hints) ? hints.match(debounceExtractor) || [] : [, hints];
    return [
      rule,
      [hintGroups[1], hintGroups[2], hintGroups[3]].reduce(
        (hints2, group2) => {
          if (!group2)
            return hints2;
          if (hasDebounce.test(group2)) {
            hints2.debounce = parseInt(group2.substr(1, group2.length - 1));
          } else {
            group2.split("").forEach(
              (hint) => has(map, hint) && Object.assign(hints2, map[hint])
            );
          }
          return hints2;
        },
        { name: rule }
      )
    ];
  }
  function fnHints(existingHints, rule) {
    if (!existingHints.name) {
      existingHints.name = rule.ruleName || rule.name;
    }
    return ["skipEmpty", "force", "debounce", "blocking"].reduce(
      (hints, hint) => {
        if (has(rule, hint) && !has(hints, hint)) {
          Object.assign(hints, {
            [hint]: rule[hint]
          });
        }
        return hints;
      },
      existingHints
    );
  }
  var validatingMessage, hintPattern, rulePattern, ruleExtractor, hintExtractor, debounceExtractor, hasDebounce, defaultHints;
  var init_dist6 = __esm({
    "packages/validation/dist/index.mjs"() {
      init_dist2();
      init_dist5();
      init_dist();
      validatingMessage = /* @__PURE__ */ createMessage({
        type: "state",
        blocking: true,
        visible: false,
        value: true,
        key: "validating"
      });
      hintPattern = "(?:[\\*+?()0-9]+)";
      rulePattern = "[a-zA-Z][a-zA-Z0-9_]+";
      ruleExtractor = new RegExp(
        `^(${hintPattern}?${rulePattern})(?:\\:(.*)+)?$`,
        "i"
      );
      hintExtractor = new RegExp(`^(${hintPattern})(${rulePattern})$`, "i");
      debounceExtractor = /([\*+?]+)?(\(\d+\))([\*+?]+)?/;
      hasDebounce = /\(\d+\)/;
      defaultHints = {
        blocking: true,
        debounce: 0,
        force: false,
        skipEmpty: true,
        name: ""
      };
    }
  });

  // packages/i18n/dist/index.mjs
  function sentence(str) {
    return str[0].toUpperCase() + str.substr(1);
  }
  function list2(items, conjunction = "or") {
    return items.reduce((oxford, item, index) => {
      oxford += item;
      if (index <= items.length - 2 && items.length > 2) {
        oxford += ", ";
      }
      if (index === items.length - 2) {
        oxford += `${items.length === 2 ? " " : ""}${conjunction} `;
      }
      return oxford;
    }, "");
  }
  function date2(date22) {
    const dateTime = typeof date22 === "string" ? new Date(Date.parse(date22)) : date22;
    if (!(dateTime instanceof Date)) {
      return "(unknown)";
    }
    return new Intl.DateTimeFormat(void 0, {
      dateStyle: "medium",
      timeZone: "UTC"
    }).format(dateTime);
  }
  function order(first, second) {
    return Number(first) >= Number(second) ? [second, first] : [first, second];
  }
  function createI18nPlugin(registry2) {
    return function i18nPlugin(node) {
      i18nNodes.add(node);
      if (activeLocale)
        node.config.locale = activeLocale;
      node.on("destroying", () => i18nNodes.delete(node));
      let localeKey = parseLocale(node.config.locale, registry2);
      let locale = localeKey ? registry2[localeKey] : {};
      node.on("prop:locale", ({ payload: lang }) => {
        localeKey = parseLocale(lang, registry2);
        locale = localeKey ? registry2[localeKey] : {};
        node.store.touch();
      });
      node.on("prop:label", () => node.store.touch());
      node.on("prop:validationLabel", () => node.store.touch());
      node.hook.text((fragment2, next) => {
        const key = fragment2.meta?.messageKey || fragment2.key;
        if (has(locale, fragment2.type) && has(locale[fragment2.type], key)) {
          const t = locale[fragment2.type][key];
          if (typeof t === "function") {
            fragment2.value = Array.isArray(fragment2.meta?.i18nArgs) ? t(...fragment2.meta.i18nArgs) : t(fragment2);
          } else {
            fragment2.value = t;
          }
        }
        return next(fragment2);
      });
    };
  }
  function parseLocale(locale, availableLocales) {
    if (has(availableLocales, locale)) {
      return locale;
    }
    const [lang] = locale.split("-");
    if (has(availableLocales, lang)) {
      return lang;
    }
    for (const locale2 in availableLocales) {
      return locale2;
    }
    return false;
  }
  function changeLocale(locale) {
    activeLocale = locale;
    for (const node of i18nNodes) {
      node.config.locale = locale;
    }
  }
  var ui10, validation10, en, i18nNodes, activeLocale;
  var init_dist7 = __esm({
    "packages/i18n/dist/index.mjs"() {
      init_dist6();
      init_dist();
      ui10 = {
        /**
         * Shown on a button for adding additional items.
         */
        add: "Add",
        /**
         * Shown when a button to remove items is visible.
         */
        remove: "Remove",
        /**
         * Shown when there are multiple items to remove at the same time.
         */
        removeAll: "Remove all",
        /**
         * Shown when all fields are not filled out correctly.
         */
        incomplete: "Sorry, not all fields are filled out correctly.",
        /**
         * Shown in a button inside a form to submit the form.
         */
        submit: "Submit",
        /**
         * Shown when no files are selected.
         */
        noFiles: "No file chosen",
        /**
         * Shown on buttons that move fields up in a list.
         */
        moveUp: "Move up",
        /**
         * Shown on buttons that move fields down in a list.
         */
        moveDown: "Move down",
        /**
         * Shown when something is actively loading.
         */
        isLoading: "Loading...",
        /**
         * Shown when there is more to load.
         */
        loadMore: "Load more",
        /**
         * Show on buttons that navigate state forward
         */
        next: "Next",
        /**
         * Show on buttons that navigate state backward
         */
        prev: "Previous",
        /**
         * Shown when adding all values.
         */
        addAllValues: "Add all values",
        /**
         * Shown when adding selected values.
         */
        addSelectedValues: "Add selected values",
        /**
         * Shown when removing all values.
         */
        removeAllValues: "Remove all values",
        /**
         * Shown when removing selected values.
         */
        removeSelectedValues: "Remove selected values",
        /**
         * Shown when there is a date to choose.
         */
        chooseDate: "Choose date",
        /**
         * Shown when there is a date to change.
         */
        changeDate: "Change date",
        /**
         * Shown above error summaries when someone attempts to submit a form with
         * errors and the developer has implemented `<FormKitSummary />`.
         */
        summaryHeader: "There were errors in your form.",
        /*
         * Shown when there is something to close
         */
        close: "Close",
        /**
         * Shown when there is something to open.
         */
        open: "Open"
      };
      validation10 = {
        /**
         * The value is not an accepted value.
         * @see {@link https://formkit.com/essentials/validation#accepted}
         */
        accepted({ name }) {
          return `Please accept the ${name}.`;
        },
        /**
         * The date is not after
         * @see {@link https://formkit.com/essentials/validation#date-after}
         */
        date_after({ name, args }) {
          if (Array.isArray(args) && args.length) {
            return `${sentence(name)} must be after ${date2(args[0])}.`;
          }
          return `${sentence(name)} must be in the future.`;
        },
        /**
         * The value is not a letter.
         * @see {@link https://formkit.com/essentials/validation#alpha}
         */
        alpha({ name }) {
          return `${sentence(name)} can only contain alphabetical characters.`;
        },
        /**
         * The value is not alphanumeric
         * @see {@link https://formkit.com/essentials/validation#alphanumeric}
         */
        alphanumeric({ name }) {
          return `${sentence(name)} can only contain letters and numbers.`;
        },
        /**
         * The value is not letter and/or spaces
         * @see {@link https://formkit.com/essentials/validation#alpha-spaces}
         */
        alpha_spaces({ name }) {
          return `${sentence(name)} can only contain letters and spaces.`;
        },
        /**
         * The value have no letter.
         * @see {@link https://formkit.com/essentials/validation#contains_alpha}
         */
        contains_alpha({ name }) {
          return `${sentence(name)} must contain alphabetical characters.`;
        },
        /**
         * The value have no alphanumeric
         * @see {@link https://formkit.com/essentials/validation#contains_alphanumeric}
         */
        contains_alphanumeric({ name }) {
          return `${sentence(name)} must contain letters or numbers.`;
        },
        /**
         * The value have no letter and/or spaces
         * @see {@link https://formkit.com/essentials/validation#contains_alpha-spaces}
         */
        contains_alpha_spaces({ name }) {
          return `${sentence(name)} must contain letters or spaces.`;
        },
        /**
         * The value have no symbol
         * @see {@link https://formkit.com/essentials/validation#contains_symbol}
         */
        contains_symbol({ name }) {
          return `${sentence(name)} must contain a symbol.`;
        },
        /**
         * The value have no uppercase
         * @see {@link https://formkit.com/essentials/validation#contains_uppercase}
         */
        contains_uppercase({ name }) {
          return `${sentence(name)} must contain an uppercase letter.`;
        },
        /**
         * The value have no lowercase
         * @see {@link https://formkit.com/essentials/validation#contains_lowercase}
         */
        contains_lowercase({ name }) {
          return `${sentence(name)} must contain a lowercase letter.`;
        },
        /**
         *  The value have no numeric
         * @see {@link https://formkit.com/essentials/validation#contains_numeric}
         */
        contains_numeric({ name }) {
          return `${sentence(name)} must contain numbers.`;
        },
        /**
         * The value is not symbol
         * @see {@link https://formkit.com/essentials/validation#symbol}
         */
        symbol({ name }) {
          return `${sentence(name)} must be a symbol.`;
        },
        /**
         * The value is not uppercase
         * @see {@link https://formkit.com/essentials/validation#uppercase}
         */
        uppercase({ name }) {
          return `${sentence(name)} can only contain uppercase letters.`;
        },
        /**
         * The value is not lowercase
         * @see {@link https://formkit.com/essentials/validation#lowercase}
         */
        lowercase({ name, args }) {
          let postfix = "";
          if (Array.isArray(args) && args.length) {
            if (args[0] === "allow_non_alpha")
              postfix = ", numbers and symbols";
            if (args[0] === "allow_numeric")
              postfix = " and numbers";
            if (args[0] === "allow_numeric_dashes")
              postfix = ", numbers and dashes";
          }
          return `${sentence(name)} can only contain lowercase letters${postfix}.`;
        },
        /**
         * The date is not before
         * @see {@link https://formkit.com/essentials/validation#date-before}
         */
        date_before({ name, args }) {
          if (Array.isArray(args) && args.length) {
            return `${sentence(name)} must be before ${date2(args[0])}.`;
          }
          return `${sentence(name)} must be in the past.`;
        },
        /**
         * The value is not between two numbers
         * @see {@link https://formkit.com/essentials/validation#between}
         */
        between({ name, args }) {
          if (isNaN(args[0]) || isNaN(args[1])) {
            return `This field was configured incorrectly and can’t be submitted.`;
          }
          const [a, b] = order(args[0], args[1]);
          return `${sentence(name)} must be between ${a} and ${b}.`;
        },
        /**
         * The confirmation field does not match
         * @see {@link https://formkit.com/essentials/validation#confirm}
         */
        confirm({ name }) {
          return `${sentence(name)} does not match.`;
        },
        /**
         * The value is not a valid date
         * @see {@link https://formkit.com/essentials/validation#date-format}
         */
        date_format({ name, args }) {
          if (Array.isArray(args) && args.length) {
            return `${sentence(name)} is not a valid date, please use the format ${args[0]}`;
          }
          return "This field was configured incorrectly and can’t be submitted";
        },
        /**
         * Is not within expected date range
         * @see {@link https://formkit.com/essentials/validation#date-between}
         */
        date_between({ name, args }) {
          return `${sentence(name)} must be between ${date2(args[0])} and ${date2(args[1])}`;
        },
        /**
         * Shown when the user-provided value is not a valid email address.
         * @see {@link https://formkit.com/essentials/validation#email}
         */
        email: "Please enter a valid email address.",
        /**
         * Does not end with the specified value
         * @see {@link https://formkit.com/essentials/validation#ends-with}
         */
        ends_with({ name, args }) {
          return `${sentence(name)} doesn’t end with ${list2(args)}.`;
        },
        /**
         * Is not an allowed value
         * @see {@link https://formkit.com/essentials/validation#is}
         */
        is({ name }) {
          return `${sentence(name)} is not an allowed value.`;
        },
        /**
         * Does not match specified length
         * @see {@link https://formkit.com/essentials/validation#length}
         */
        length({ name, args: [first = 0, second = Infinity] }) {
          const min3 = Number(first) <= Number(second) ? first : second;
          const max3 = Number(second) >= Number(first) ? second : first;
          if (min3 == 1 && max3 === Infinity) {
            return `${sentence(name)} must be at least one character.`;
          }
          if (min3 == 0 && max3) {
            return `${sentence(name)} must be less than or equal to ${max3} characters.`;
          }
          if (min3 === max3) {
            return `${sentence(name)} should be ${max3} characters long.`;
          }
          if (min3 && max3 === Infinity) {
            return `${sentence(name)} must be greater than or equal to ${min3} characters.`;
          }
          return `${sentence(name)} must be between ${min3} and ${max3} characters.`;
        },
        /**
         * Value is not a match
         * @see {@link https://formkit.com/essentials/validation#matches}
         */
        matches({ name }) {
          return `${sentence(name)} is not an allowed value.`;
        },
        /**
         * Exceeds maximum allowed value
         * @see {@link https://formkit.com/essentials/validation#max}
         */
        max({ name, node: { value }, args }) {
          if (Array.isArray(value)) {
            return `Cannot have more than ${args[0]} ${name}.`;
          }
          return `${sentence(name)} must be no more than ${args[0]}.`;
        },
        /**
         * The (field-level) value does not match specified mime type
         * @see {@link https://formkit.com/essentials/validation#mime}
         */
        mime({ name, args }) {
          if (!args[0]) {
            return "No file formats allowed.";
          }
          return `${sentence(name)} must be of the type: ${args[0]}`;
        },
        /**
         * Does not fulfill minimum allowed value
         * @see {@link https://formkit.com/essentials/validation#min}
         */
        min({ name, node: { value }, args }) {
          if (Array.isArray(value)) {
            return `Cannot have fewer than ${args[0]} ${name}.`;
          }
          return `${sentence(name)} must be at least ${args[0]}.`;
        },
        /**
         * Is not an allowed value
         * @see {@link https://formkit.com/essentials/validation#not}
         */
        not({ name, node: { value } }) {
          return `“${value}” is not an allowed ${name}.`;
        },
        /**
         *  Is not a number
         * @see {@link https://formkit.com/essentials/validation#number}
         */
        number({ name }) {
          return `${sentence(name)} must be a number.`;
        },
        /**
         * Require one field.
         * @see {@link https://formkit.com/essentials/validation#require-one}
         */
        require_one: ({ name, node, args: inputNames }) => {
          const labels = inputNames.map((name2) => {
            const dependentNode = node.at(name2);
            if (dependentNode) {
              return createMessageName(dependentNode);
            }
            return false;
          }).filter((name2) => !!name2);
          labels.unshift(name);
          return `${labels.join(" or ")} is required.`;
        },
        /**
         * Required field.
         * @see {@link https://formkit.com/essentials/validation#required}
         */
        required({ name }) {
          return `${sentence(name)} is required.`;
        },
        /**
         * Does not start with specified value
         * @see {@link https://formkit.com/essentials/validation#starts-with}
         */
        starts_with({ name, args }) {
          return `${sentence(name)} doesn’t start with ${list2(args)}.`;
        },
        /**
         * Is not a url
         * @see {@link https://formkit.com/essentials/validation#url}
         */
        url() {
          return `Please enter a valid URL.`;
        },
        /**
         * Shown when the date is invalid.
         */
        invalidDate: "The selected date is invalid."
      };
      en = { ui: ui10, validation: validation10 };
      i18nNodes = /* @__PURE__ */ new Set();
      activeLocale = null;
    }
  });

  // packages/themes/dist/index.mjs
  function createThemePlugin(theme, icons, iconLoaderUrl, iconLoader) {
    if (icons) {
      Object.assign(iconRegistry, icons);
    }
    if (isClient && !themeWasRequested && documentStyles?.getPropertyValue("--formkit-theme")) {
      themeDidLoad();
      themeWasRequested = true;
    } else if (theme && !themeWasRequested && isClient) {
      loadTheme(theme);
    } else if (!themeWasRequested && isClient) {
      themeDidLoad();
    }
    const themePlugin = function themePlugin2(node) {
      node.addProps(["iconLoader", "iconLoaderUrl"]);
      node.props.iconHandler = createIconHandler(
        node.props?.iconLoader ? node.props.iconLoader : iconLoader,
        node.props?.iconLoaderUrl ? node.props.iconLoaderUrl : iconLoaderUrl
      );
      loadIconPropIcons(node, node.props.iconHandler);
      node.on("created", () => {
        if (node?.context?.handlers) {
          node.context.handlers.iconClick = (sectionKey) => {
            const clickHandlerProp = `on${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}IconClick`;
            const handlerFunction = node.props[clickHandlerProp];
            if (handlerFunction && typeof handlerFunction === "function") {
              return (e) => {
                return handlerFunction(node, e);
              };
            }
            return void 0;
          };
        }
        if (node?.context?.fns) {
          node.context.fns.iconRole = (sectionKey) => {
            const clickHandlerProp = `on${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}IconClick`;
            return typeof node.props[clickHandlerProp] === "function" ? "button" : null;
          };
        }
      });
    };
    themePlugin.iconHandler = createIconHandler(iconLoader, iconLoaderUrl);
    return themePlugin;
  }
  function loadTheme(theme) {
    if (!theme || !isClient || typeof getComputedStyle !== "function") {
      return;
    }
    themeWasRequested = true;
    documentThemeLinkTag = document.getElementById("formkit-theme");
    if (theme && // if we have a window object
    isClient && // we don't have an existing theme OR the theme being set up is different
    (!documentStyles?.getPropertyValue("--formkit-theme") && !documentThemeLinkTag || documentThemeLinkTag?.getAttribute("data-theme") && documentThemeLinkTag?.getAttribute("data-theme") !== theme)) {
      const formkitVersion = FORMKIT_VERSION.startsWith("__") ? "latest" : FORMKIT_VERSION;
      const themeUrl = `https://cdn.jsdelivr.net/npm/@formkit/themes@${formkitVersion}/dist/${theme}/theme.css`;
      const link = document.createElement("link");
      link.type = "text/css";
      link.rel = "stylesheet";
      link.id = "formkit-theme";
      link.setAttribute("data-theme", theme);
      link.onload = () => {
        documentStyles = getComputedStyle(document.documentElement);
        themeDidLoad();
      };
      document.head.appendChild(link);
      link.href = themeUrl;
      if (documentThemeLinkTag) {
        documentThemeLinkTag.remove();
      }
    }
  }
  function createIconHandler(iconLoader, iconLoaderUrl) {
    return (iconName) => {
      if (typeof iconName !== "string")
        return;
      if (iconName.startsWith("<svg")) {
        return iconName;
      }
      const isDefault = iconName.startsWith("default:");
      iconName = isDefault ? iconName.split(":")[1] : iconName;
      const iconWasAlreadyLoaded = iconName in iconRegistry;
      let loadedIcon = void 0;
      if (iconWasAlreadyLoaded) {
        return iconRegistry[iconName];
      } else if (!iconRequests[iconName]) {
        loadedIcon = getIconFromStylesheet(iconName);
        loadedIcon = isClient && typeof loadedIcon === "undefined" ? Promise.resolve(loadedIcon) : loadedIcon;
        if (loadedIcon instanceof Promise) {
          iconRequests[iconName] = loadedIcon.then((iconValue) => {
            if (!iconValue && typeof iconName === "string" && !isDefault) {
              return loadedIcon = typeof iconLoader === "function" ? iconLoader(iconName) : getRemoteIcon(iconName, iconLoaderUrl);
            }
            return iconValue;
          }).then((finalIcon) => {
            if (typeof iconName === "string") {
              iconRegistry[isDefault ? `default:${iconName}` : iconName] = finalIcon;
            }
            return finalIcon;
          });
        } else if (typeof loadedIcon === "string") {
          iconRegistry[isDefault ? `default:${iconName}` : iconName] = loadedIcon;
          return loadedIcon;
        }
      }
      return iconRequests[iconName];
    };
  }
  function getIconFromStylesheet(iconName) {
    if (!isClient)
      return;
    if (themeHasLoaded) {
      return loadStylesheetIcon(iconName);
    } else {
      return themeLoaded.then(() => {
        return loadStylesheetIcon(iconName);
      });
    }
  }
  function loadStylesheetIcon(iconName) {
    const cssVarIcon = documentStyles?.getPropertyValue(`--fk-icon-${iconName}`);
    if (cssVarIcon) {
      const icon2 = atob(cssVarIcon);
      if (icon2.startsWith("<svg")) {
        iconRegistry[iconName] = icon2;
        return icon2;
      }
    }
    return void 0;
  }
  function getRemoteIcon(iconName, iconLoaderUrl) {
    const formkitVersion = FORMKIT_VERSION.startsWith("__") ? "latest" : FORMKIT_VERSION;
    const fetchUrl = typeof iconLoaderUrl === "function" ? iconLoaderUrl(iconName) : `https://cdn.jsdelivr.net/npm/@formkit/icons@${formkitVersion}/dist/icons/${iconName}.svg`;
    if (!isClient)
      return void 0;
    return fetch(`${fetchUrl}`).then(async (r) => {
      const icon2 = await r.text();
      if (icon2.startsWith("<svg")) {
        return icon2;
      }
      return void 0;
    }).catch((e) => {
      console.error(e);
      return void 0;
    });
  }
  function loadIconPropIcons(node, iconHandler) {
    const iconRegex = /^[a-zA-Z-]+(?:-icon|Icon)$/;
    const iconProps = Object.keys(node.props).filter((prop) => {
      return iconRegex.test(prop);
    });
    iconProps.forEach((sectionKey) => {
      return loadPropIcon(node, iconHandler, sectionKey);
    });
  }
  function loadPropIcon(node, iconHandler, sectionKey) {
    const iconName = node.props[sectionKey];
    const loadedIcon = iconHandler(iconName);
    const rawIconProp = `_raw${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}`;
    const clickHandlerProp = `on${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}Click`;
    node.addProps([rawIconProp, clickHandlerProp]);
    node.on(`prop:${sectionKey}`, reloadIcon);
    if (loadedIcon instanceof Promise) {
      return loadedIcon.then((svg) => {
        node.props[rawIconProp] = svg;
      });
    } else {
      node.props[rawIconProp] = loadedIcon;
    }
    return;
  }
  function reloadIcon(event) {
    const node = event.origin;
    const iconName = event.payload;
    const iconHandler = node?.props?.iconHandler;
    const sectionKey = event.name.split(":")[1];
    const rawIconProp = `_raw${sectionKey.charAt(0).toUpperCase()}${sectionKey.slice(1)}`;
    if (iconHandler && typeof iconHandler === "function") {
      const loadedIcon = iconHandler(iconName);
      if (loadedIcon instanceof Promise) {
        return loadedIcon.then((svg) => {
          node.props[rawIconProp] = svg;
        });
      } else {
        node.props[rawIconProp] = loadedIcon;
      }
    }
  }
  var documentStyles, documentThemeLinkTag, themeDidLoad, themeHasLoaded, themeWasRequested, themeLoaded, isClient, iconRegistry, iconRequests;
  var init_dist8 = __esm({
    "packages/themes/dist/index.mjs"() {
      init_dist2();
      documentStyles = void 0;
      documentThemeLinkTag = null;
      themeHasLoaded = false;
      themeWasRequested = false;
      themeLoaded = /* @__PURE__ */ new Promise((res) => {
        themeDidLoad = () => {
          themeHasLoaded = true;
          res();
        };
      });
      isClient = typeof window !== "undefined" && typeof fetch !== "undefined";
      documentStyles = isClient ? /* @__PURE__ */ getComputedStyle(document.documentElement) : void 0;
      iconRegistry = {};
      iconRequests = {};
    }
  });
  var vueBindings; exports.bindings = void 0;
  var init_bindings = __esm({
    "packages/vue/src/bindings.ts"() {
      init_dist2();
      init_dist();
      init_dist5();
      vueBindings = function vueBindings2(node) {
        node.ledger.count("blocking", (m) => m.blocking);
        const isValid = Vue.ref(!node.ledger.value("blocking"));
        node.ledger.count("errors", (m) => m.type === "error");
        const hasErrors = Vue.ref(!!node.ledger.value("errors"));
        let hasTicked = false;
        Vue.nextTick(() => {
          hasTicked = true;
        });
        const availableMessages = Vue.reactive(
          node.store.reduce((store, message4) => {
            if (message4.visible) {
              store[message4.key] = message4;
            }
            return store;
          }, {})
        );
        const validationVisibility = Vue.ref(
          node.props.validationVisibility || (node.props.type === "checkbox" ? "dirty" : "blur")
        );
        node.on("prop:validationVisibility", ({ payload }) => {
          validationVisibility.value = payload;
        });
        const hasShownErrors = Vue.ref(validationVisibility.value === "live");
        const isRequired = Vue.ref(false);
        const checkForRequired = (parsedRules) => {
          isRequired.value = (parsedRules ?? []).some(
            (rule) => rule.name === "required"
          );
        };
        checkForRequired(node.props.parsedRules);
        node.on("prop:parsedRules", ({ payload }) => checkForRequired(payload));
        const items = Vue.ref(node.children.map((child) => child.uid));
        const validationVisible = Vue.computed(() => {
          if (!context.state)
            return false;
          if (context.state.submitted)
            return true;
          if (!hasShownErrors.value && !context.state.settled) {
            return false;
          }
          switch (validationVisibility.value) {
            case "live":
              return true;
            case "blur":
              return context.state.blurred;
            case "dirty":
              return context.state.dirty;
            default:
              return false;
          }
        });
        const isInvalid = Vue.computed(() => {
          return context.state.failing && validationVisible.value;
        });
        const isComplete = Vue.computed(() => {
          return context && hasValidation.value ? isValid.value && !hasErrors.value : context.state.dirty && !empty(context.value);
        });
        const hasValidation = Vue.ref(
          Array.isArray(node.props.parsedRules) && node.props.parsedRules.length > 0
        );
        node.on("prop:parsedRules", ({ payload: rules }) => {
          hasValidation.value = Array.isArray(rules) && rules.length > 0;
        });
        const messages4 = Vue.computed(() => {
          const visibleMessages = {};
          for (const key in availableMessages) {
            const message4 = availableMessages[key];
            if (message4.type !== "validation" || validationVisible.value) {
              visibleMessages[key] = message4;
            }
          }
          return visibleMessages;
        });
        const ui = Vue.reactive(
          node.store.reduce((messages5, message4) => {
            if (message4.type === "ui" && message4.visible)
              messages5[message4.key] = message4;
            return messages5;
          }, {})
        );
        const passing = Vue.computed(() => !context.state.failing);
        const cachedClasses = Vue.reactive({});
        const classes2 = new Proxy(cachedClasses, {
          get(...args) {
            if (!node)
              return "";
            const [target, property] = args;
            let className = Reflect.get(...args);
            if (!className && typeof property === "string") {
              if (!has(target, property) && !property.startsWith("__v")) {
                const observedNode = createObserver(node);
                observedNode.watch((node2) => {
                  const rootClasses = typeof node2.config.rootClasses === "function" ? node2.config.rootClasses(property, node2) : {};
                  const globalConfigClasses = node2.config.classes ? createClasses(property, node2, node2.config.classes[property]) : {};
                  const classesPropClasses = createClasses(
                    property,
                    node2,
                    node2.props[`_${property}Class`]
                  );
                  const sectionPropClasses = createClasses(
                    property,
                    node2,
                    node2.props[`${property}Class`]
                  );
                  className = generateClassList(
                    node2,
                    property,
                    rootClasses,
                    globalConfigClasses,
                    classesPropClasses,
                    sectionPropClasses
                  );
                  target[property] = className ?? "";
                });
              }
            }
            return className;
          }
        });
        node.on("prop:rootClasses", () => {
          const keys = Object.keys(cachedClasses);
          for (const key of keys) {
            delete cachedClasses[key];
          }
        });
        const describedBy = Vue.computed(() => {
          if (!node)
            return void 0;
          const describers = [];
          if (context.help) {
            describers.push(`help-${node.props.id}`);
          }
          for (const key in messages4.value) {
            describers.push(`${node.props.id}-${key}`);
          }
          return describers.length ? describers.join(" ") : void 0;
        });
        const value = Vue.ref(node.value);
        const _value = Vue.ref(node.value);
        const context = Vue.reactive({
          _value,
          attrs: node.props.attrs,
          disabled: node.props.disabled,
          describedBy,
          fns: {
            length: (obj) => Object.keys(obj).length,
            number: (value2) => Number(value2),
            string: (value2) => String(value2),
            json: (value2) => JSON.stringify(value2),
            eq
          },
          handlers: {
            blur: (e) => {
              if (!node)
                return;
              node.store.set(
                /* @__PURE__ */ createMessage({ key: "blurred", visible: false, value: true })
              );
              if (typeof node.props.attrs.onBlur === "function") {
                node.props.attrs.onBlur(e);
              }
            },
            touch: () => {
              const doCompare = context.dirtyBehavior === "compare";
              if (node.store.dirty?.value && !doCompare)
                return;
              const isDirty = !eq(node.props._init, node._value);
              if (!isDirty && !doCompare)
                return;
              node.store.set(
                /* @__PURE__ */ createMessage({ key: "dirty", visible: false, value: isDirty })
              );
            },
            DOMInput: (e) => {
              node.input(e.target.value);
              node.emit("dom-input-event", e);
            }
          },
          help: node.props.help,
          id: node.props.id,
          items,
          label: node.props.label,
          messages: messages4,
          didMount: false,
          node: Vue.markRaw(node),
          options: node.props.options,
          defaultMessagePlacement: true,
          slots: node.props.__slots,
          state: {
            blurred: false,
            complete: isComplete,
            dirty: false,
            empty: empty(value),
            submitted: false,
            settled: node.isSettled,
            valid: isValid,
            invalid: isInvalid,
            errors: hasErrors,
            rules: hasValidation,
            validationVisible,
            required: isRequired,
            failing: false,
            passing
          },
          type: node.props.type,
          family: node.props.family,
          ui,
          value,
          classes: classes2
        });
        node.on("created", () => {
          if (!eq(context.value, node.value)) {
            _value.value = node.value;
            value.value = node.value;
            Vue.triggerRef(value);
            Vue.triggerRef(_value);
          }
          (async () => {
            await node.settled;
            if (node)
              node.props._init = cloneAny(node.value);
          })();
        });
        node.on("mounted", () => {
          context.didMount = true;
        });
        node.on("settled", ({ payload: isSettled }) => {
          context.state.settled = isSettled;
        });
        function observeProps(observe) {
          const propNames = Array.isArray(observe) ? observe : Object.keys(observe);
          propNames.forEach((prop) => {
            prop = camel(prop);
            if (!has(context, prop)) {
              context[prop] = node.props[prop];
            }
            node.on(`prop:${prop}`, ({ payload }) => {
              context[prop] = payload;
            });
          });
        }
        const rootProps = () => {
          const props = [
            "__root",
            "help",
            "label",
            "disabled",
            "options",
            "type",
            "attrs",
            "preserve",
            "preserveErrors",
            "id",
            "dirtyBehavior"
          ];
          const iconPattern = /^[a-zA-Z-]+(?:-icon|Icon)$/;
          const matchingProps = Object.keys(node.props).filter((prop) => {
            return iconPattern.test(prop);
          });
          return props.concat(matchingProps);
        };
        observeProps(rootProps());
        function definedAs(definition3) {
          if (definition3.props)
            observeProps(definition3.props);
        }
        node.props.definition && definedAs(node.props.definition);
        node.on("added-props", ({ payload }) => observeProps(payload));
        node.on("input", ({ payload }) => {
          if (node.type !== "input" && !Vue.isRef(payload) && !Vue.isReactive(payload)) {
            _value.value = shallowClone(payload);
          } else {
            _value.value = payload;
            Vue.triggerRef(_value);
          }
        });
        node.on("commitRaw", ({ payload }) => {
          if (node.type !== "input" && !Vue.isRef(payload) && !Vue.isReactive(payload)) {
            value.value = _value.value = shallowClone(payload);
          } else {
            value.value = _value.value = payload;
            Vue.triggerRef(value);
          }
          node.emit("modelUpdated");
        });
        node.on("commit", ({ payload }) => {
          if ((!context.state.dirty || context.dirtyBehavior === "compare") && node.isCreated && hasTicked) {
            if (!node.store.validating?.value) {
              context.handlers.touch();
            } else {
              const receipt = node.on("message-removed", ({ payload: message4 }) => {
                if (message4.key === "validating") {
                  context.handlers.touch();
                  node.off(receipt);
                }
              });
            }
          }
          if (isComplete && node.type === "input" && hasErrors.value && !undefine(node.props.preserveErrors)) {
            node.store.filter(
              (message4) => !(message4.type === "error" && message4.meta?.autoClear === true)
            );
          }
          if (node.type === "list" && node.sync) {
            items.value = node.children.map((child) => child.uid);
          }
          context.state.empty = empty(payload);
        });
        const updateState = async (message4) => {
          if (message4.type === "ui" && message4.visible && !message4.meta.showAsMessage) {
            ui[message4.key] = message4;
          } else if (message4.visible) {
            availableMessages[message4.key] = message4;
          } else if (message4.type === "state") {
            context.state[message4.key] = !!message4.value;
          }
        };
        node.on("message-added", (e) => updateState(e.payload));
        node.on("message-updated", (e) => updateState(e.payload));
        node.on("message-removed", ({ payload: message4 }) => {
          delete ui[message4.key];
          delete availableMessages[message4.key];
          delete context.state[message4.key];
        });
        node.on("settled:blocking", () => {
          isValid.value = true;
        });
        node.on("unsettled:blocking", () => {
          isValid.value = false;
        });
        node.on("settled:errors", () => {
          hasErrors.value = false;
        });
        node.on("unsettled:errors", () => {
          hasErrors.value = true;
        });
        Vue.watch(validationVisible, (value2) => {
          if (value2) {
            hasShownErrors.value = true;
          }
        });
        node.context = context;
        node.emit("context", node, false);
        node.on("destroyed", () => {
          node.context = void 0;
          node = null;
        });
      };
      exports.bindings = vueBindings;
    }
  });

  // packages/dev/dist/index.mjs
  function register2() {
    if (!registered) {
      exports.errorHandler(decodeErrors);
      warningHandler(decodeWarnings);
      registered = true;
    }
  }
  var errors, warnings, decodeErrors, registered, decodeWarnings;
  var init_dist9 = __esm({
    "packages/dev/dist/index.mjs"() {
      init_dist2();
      errors = {
        /**
         * FormKit errors:
         */
        100: ({ data: node }) => `Only groups, lists, and forms can have children (${node.name}).`,
        101: ({ data: node }) => `You cannot directly modify the store (${node.name}). See: https://formkit.com/advanced/core#message-store`,
        102: ({
          data: [node, property]
        }) => `You cannot directly assign node.${property} (${node.name})`,
        103: ({ data: [operator] }) => `Schema expressions cannot start with an operator (${operator})`,
        104: ({ data: [operator, expression] }) => `Schema expressions cannot end with an operator (${operator} in "${expression}")`,
        105: ({ data: expression }) => `Invalid schema expression: ${expression}`,
        106: ({ data: name }) => `Cannot submit because (${name}) is not in a form.`,
        107: ({ data: [node, value] }) => `Cannot set ${node.name} to non object value: ${value}`,
        108: ({ data: [node, value] }) => `Cannot set ${node.name} to non array value: ${value}`,
        /**
         * Input specific errors:
         */
        300: ({ data: [node] }) => `Cannot set behavior prop to overscroll (on ${node.name} input) when options prop is a function.`,
        /**
         * FormKit vue errors:
         */
        600: ({ data: node }) => `Unknown input type${typeof node.props.type === "string" ? ' "' + node.props.type + '"' : ""} ("${node.name}")`,
        601: ({ data: node }) => `Input definition${typeof node.props.type === "string" ? ' "' + node.props.type + '"' : ""} is missing a schema or component property (${node.name}).`
      };
      warnings = {
        /**
         * Core warnings:
         */
        150: ({ data: fn }) => `Schema function "${fn}()" is not a valid function.`,
        151: ({ data: id }) => `No form element with id: ${id}`,
        152: ({ data: id }) => `No input element with id: ${id}`,
        /**
         * Input specific warnings:
         */
        350: ({
          data: { node, inputType }
        }) => `Invalid options prop for ${node.name} input (${inputType}). See https://formkit.com/inputs/${inputType}`,
        /**
         * Vue warnings:
         */
        650: 'Schema "$get()" must use the id of an input to access.',
        651: ({ data: id }) => `Cannot setErrors() on "${id}" because no such id exists.`,
        652: ({ data: id }) => `Cannot clearErrors() on "${id}" because no such id exists.`,
        /**
         * Deprecation warnings:
         */
        800: ({ data: name }) => `${name} is deprecated.`
      };
      decodeErrors = (error2, next) => {
        if (error2.code in errors) {
          const err = errors[error2.code];
          error2.message = typeof err === "function" ? err(error2) : err;
        }
        return next(error2);
      };
      registered = false;
      decodeWarnings = (warning, next) => {
        if (warning.code in warnings) {
          const warn2 = warnings[warning.code];
          warning.message = typeof warn2 === "function" ? warn2(warning) : warn2;
        }
        return next(warning);
      };
    }
  });

  // packages/vue/src/defaultConfig.ts
  var defaultConfig_exports = {};
  __export(defaultConfig_exports, {
    defaultConfig: () => exports.defaultConfig
  });
  exports.defaultConfig = void 0;
  var init_defaultConfig = __esm({
    "packages/vue/src/defaultConfig.ts"() {
      init_dist();
      init_dist4();
      init_dist6();
      init_dist7();
      init_dist3();
      init_dist8();
      init_bindings();
      init_dist9();
      exports.defaultConfig = (options2 = {}) => {
        register2();
        const {
          rules = {},
          locales = {},
          inputs: inputs2 = {},
          messages: messages4 = {},
          locale = void 0,
          theme = void 0,
          iconLoaderUrl = void 0,
          iconLoader = void 0,
          icons = {},
          ...nodeOptions
        } = options2;
        const validation = createValidationPlugin({
          ...dist_exports,
          ...rules || {}
        });
        const i18n = createI18nPlugin(
          extend({ en, ...locales || {} }, messages4)
        );
        const library = createLibraryPlugin(inputs, inputs2);
        const themePlugin = createThemePlugin(theme, icons, iconLoaderUrl, iconLoader);
        return extend(
          {
            plugins: [library, themePlugin, exports.bindings, i18n, validation],
            ...!locale ? {} : { config: { locale } }
          },
          nodeOptions || {},
          true
        );
      };
    }
  });

  // packages/vue/src/FormKit.ts
  init_dist2();

  // packages/vue/src/FormKitSchema.ts
  init_dist();
  init_dist2();

  // packages/vue/src/composables/onSSRComplete.ts
  var isServer = typeof window === "undefined";
  var ssrCompleteRegistry = /* @__PURE__ */ new Map();
  function ssrComplete(app) {
    if (!isServer)
      return;
    const callbacks = ssrCompleteRegistry.get(app);
    if (!callbacks)
      return;
    for (const callback of callbacks) {
      callback();
    }
    callbacks.clear();
    ssrCompleteRegistry.delete(app);
  }
  function onSSRComplete(app, callback) {
    if (!isServer || !app)
      return;
    if (!ssrCompleteRegistry.has(app))
      ssrCompleteRegistry.set(app, /* @__PURE__ */ new Set());
    ssrCompleteRegistry.get(app)?.add(callback);
  }

  // packages/vue/src/FormKitSchema.ts
  var isServer2 = typeof window === "undefined";
  var memo = {};
  var memoKeys = {};
  var instanceKey;
  var instanceScopes = /* @__PURE__ */ new WeakMap();
  var raw = "__raw__";
  var isClassProp = /[a-zA-Z0-9\-][cC]lass$/;
  function getRef(token2, data) {
    const value = Vue.ref(null);
    if (token2 === "get") {
      const nodeRefs = {};
      value.value = get.bind(null, nodeRefs);
      return value;
    }
    const path = token2.split(".");
    Vue.watchEffect(() => {
      value.value = getValue(
        Vue.isRef(data) ? data.value : data,
        path
      );
    });
    return value;
  }
  function getValue(set, path) {
    if (Array.isArray(set)) {
      for (const subset of set) {
        const value = subset !== false && getValue(subset, path);
        if (value !== void 0)
          return value;
      }
      return void 0;
    }
    let foundValue = void 0;
    let obj = set;
    for (const i in path) {
      const key = path[i];
      if (typeof obj !== "object" || obj === null) {
        foundValue = void 0;
        break;
      }
      const currentValue = obj[key];
      if (Number(i) === path.length - 1 && currentValue !== void 0) {
        foundValue = typeof currentValue === "function" ? currentValue.bind(obj) : currentValue;
        break;
      }
      obj = currentValue;
    }
    return foundValue;
  }
  function get(nodeRefs, id) {
    if (typeof id !== "string")
      return warn(650);
    if (!(id in nodeRefs))
      nodeRefs[id] = Vue.ref(void 0);
    if (nodeRefs[id].value === void 0) {
      nodeRefs[id].value = null;
      const root = getNode(id);
      if (root)
        nodeRefs[id].value = root.context;
      watchRegistry(id, ({ payload: node }) => {
        nodeRefs[id].value = isNode(node) ? node.context : node;
      });
    }
    return nodeRefs[id].value;
  }
  function parseSchema(library, schema, memoKey) {
    function parseCondition2(library2, node) {
      const condition = provider(compile(node.if), { if: true });
      const children = createElements(library2, node.then);
      const alternate = node.else ? createElements(library2, node.else) : null;
      return [condition, children, alternate];
    }
    function parseConditionAttr(attr, _default) {
      const condition = provider(compile(attr.if));
      let b = () => _default;
      let a = () => _default;
      if (typeof attr.then === "object") {
        a = parseAttrs(attr.then, void 0);
      } else if (typeof attr.then === "string" && attr.then?.startsWith("$")) {
        a = provider(compile(attr.then));
      } else {
        a = () => attr.then;
      }
      if (has(attr, "else")) {
        if (typeof attr.else === "object") {
          b = parseAttrs(attr.else);
        } else if (typeof attr.else === "string" && attr.else?.startsWith("$")) {
          b = provider(compile(attr.else));
        } else {
          b = () => attr.else;
        }
      }
      return () => condition() ? a() : b();
    }
    function parseAttrs(unparsedAttrs, bindExp, _default = {}) {
      const explicitAttrs = new Set(Object.keys(unparsedAttrs || {}));
      const boundAttrs = bindExp ? provider(compile(bindExp)) : () => ({});
      const setters = [
        (attrs) => {
          const bound = boundAttrs();
          for (const attr in bound) {
            if (!explicitAttrs.has(attr)) {
              attrs[attr] = bound[attr];
            }
          }
        }
      ];
      if (unparsedAttrs) {
        if (isConditional(unparsedAttrs)) {
          const condition = parseConditionAttr(
            unparsedAttrs,
            _default
          );
          return condition;
        }
        for (let attr in unparsedAttrs) {
          const value = unparsedAttrs[attr];
          let getValue2;
          const isStr = typeof value === "string";
          if (attr.startsWith(raw)) {
            attr = attr.substring(7);
            getValue2 = () => value;
          } else if (isStr && value.startsWith("$") && value.length > 1 && !(value.startsWith("$reset") && isClassProp.test(attr))) {
            getValue2 = provider(compile(value));
          } else if (typeof value === "object" && isConditional(value)) {
            getValue2 = parseConditionAttr(value, void 0);
          } else if (typeof value === "object" && isPojo(value)) {
            getValue2 = parseAttrs(value);
          } else {
            getValue2 = () => value;
          }
          setters.push((attrs) => {
            attrs[attr] = getValue2();
          });
        }
      }
      return () => {
        const attrs = Array.isArray(unparsedAttrs) ? [] : {};
        setters.forEach((setter) => setter(attrs));
        return attrs;
      };
    }
    function parseNode(library2, _node) {
      let element = null;
      let attrs = () => null;
      let condition = false;
      let children = null;
      let alternate = null;
      let iterator = null;
      let resolve = false;
      const node = sugar(_node);
      if (isDOM(node)) {
        element = node.$el;
        attrs = node.$el !== "text" ? parseAttrs(node.attrs, node.bind) : () => null;
      } else if (isComponent(node)) {
        if (typeof node.$cmp === "string") {
          if (has(library2, node.$cmp)) {
            element = library2[node.$cmp];
          } else {
            element = node.$cmp;
            resolve = true;
          }
        } else {
          element = node.$cmp;
        }
        attrs = parseAttrs(node.props, node.bind);
      } else if (isConditional(node)) {
        [condition, children, alternate] = parseCondition2(library2, node);
      }
      if (!isConditional(node) && "if" in node) {
        condition = provider(compile(node.if));
      } else if (!isConditional(node) && element === null) {
        condition = () => true;
      }
      if ("children" in node && node.children) {
        if (typeof node.children === "string") {
          if (node.children.startsWith("$slots.")) {
            element = element === "text" ? "slot" : element;
            children = provider(compile(node.children));
          } else if (node.children.startsWith("$") && node.children.length > 1) {
            const value = provider(compile(node.children));
            children = () => String(value());
          } else {
            children = () => String(node.children);
          }
        } else if (Array.isArray(node.children)) {
          children = createElements(library2, node.children);
        } else {
          const [childCondition, c, a] = parseCondition2(library2, node.children);
          children = (iterationData) => childCondition && childCondition() ? c && c(iterationData) : a && a(iterationData);
        }
      }
      if (isComponent(node)) {
        if (children) {
          const produceChildren = children;
          children = (iterationData) => {
            return {
              default(slotData2, key) {
                const currentKey = instanceKey;
                if (key)
                  instanceKey = key;
                if (slotData2)
                  instanceScopes.get(instanceKey)?.unshift(slotData2);
                if (iterationData)
                  instanceScopes.get(instanceKey)?.unshift(iterationData);
                const c = produceChildren(iterationData);
                if (slotData2)
                  instanceScopes.get(instanceKey)?.shift();
                if (iterationData)
                  instanceScopes.get(instanceKey)?.shift();
                instanceKey = currentKey;
                return c;
              }
            };
          };
          children.slot = true;
        } else {
          children = () => ({});
        }
      }
      if ("for" in node && node.for) {
        const values = node.for.length === 3 ? node.for[2] : node.for[1];
        const getValues = typeof values === "string" && values.startsWith("$") ? provider(compile(values)) : () => values;
        iterator = [
          getValues,
          node.for[0],
          node.for.length === 3 ? String(node.for[1]) : null
        ];
      }
      return [condition, element, attrs, children, alternate, iterator, resolve];
    }
    function createSlots(children, iterationData) {
      const slots = children(iterationData);
      const currentKey = instanceKey;
      return Object.keys(slots).reduce((allSlots, slotName) => {
        const slotFn = slots && slots[slotName];
        allSlots[slotName] = (data) => {
          return slotFn && slotFn(data, currentKey) || null;
        };
        return allSlots;
      }, {});
    }
    function createElement(library2, node) {
      const [condition, element, attrs, children, alternate, iterator, resolve] = parseNode(library2, node);
      let createNodes = (iterationData) => {
        if (condition && element === null && children) {
          return condition() ? children(iterationData) : alternate && alternate(iterationData);
        }
        if (element && (!condition || condition())) {
          if (element === "text" && children) {
            return Vue.createTextVNode(String(children()));
          }
          if (element === "slot" && children)
            return children(iterationData);
          const el = resolve ? Vue.resolveComponent(element) : element;
          const slots = children?.slot ? createSlots(children, iterationData) : null;
          return Vue.h(
            el,
            attrs(),
            slots || (children ? children(iterationData) : [])
          );
        }
        return typeof alternate === "function" ? alternate(iterationData) : alternate;
      };
      if (iterator) {
        const repeatedNode = createNodes;
        const [getValues, valueName, keyName] = iterator;
        createNodes = () => {
          const _v = getValues();
          const values = Number.isFinite(_v) ? Array(Number(_v)).fill(0).map((_, i) => i) : _v;
          const fragment2 = [];
          if (typeof values !== "object")
            return null;
          const instanceScope = instanceScopes.get(instanceKey) || [];
          const isArray = Array.isArray(values);
          for (const key in values) {
            if (isArray && key in Array.prototype)
              continue;
            const iterationData = Object.defineProperty(
              {
                ...instanceScope.reduce(
                  (previousIterationData, scopedData) => {
                    if (previousIterationData.__idata) {
                      return { ...previousIterationData, ...scopedData };
                    }
                    return scopedData;
                  },
                  {}
                ),
                [valueName]: values[key],
                ...keyName !== null ? { [keyName]: isArray ? Number(key) : key } : {}
              },
              "__idata",
              { enumerable: false, value: true }
            );
            instanceScope.unshift(iterationData);
            fragment2.push(repeatedNode.bind(null, iterationData)());
            instanceScope.shift();
          }
          return fragment2;
        };
      }
      return createNodes;
    }
    function createElements(library2, schema2) {
      if (Array.isArray(schema2)) {
        const els = schema2.map(createElement.bind(null, library2));
        return (iterationData) => els.map((element2) => element2(iterationData));
      }
      const element = createElement(library2, schema2);
      return (iterationData) => element(iterationData);
    }
    const providers = [];
    function provider(compiled, hints = {}) {
      const compiledFns = /* @__PURE__ */ new WeakMap();
      providers.push((callback, key) => {
        compiledFns.set(
          key,
          compiled.provide((tokens) => callback(tokens, hints))
        );
      });
      return () => compiledFns.get(instanceKey)();
    }
    function createInstance(providerCallback, key) {
      memoKey ?? (memoKey = toMemoKey(schema));
      const [render, compiledProviders] = has(memo, memoKey) ? memo[memoKey] : [createElements(library, schema), providers];
      if (!isServer2) {
        memoKeys[memoKey] ?? (memoKeys[memoKey] = 0);
        memoKeys[memoKey]++;
        memo[memoKey] = [render, compiledProviders];
      }
      compiledProviders.forEach((compiledProvider) => {
        compiledProvider(providerCallback, key);
      });
      return () => {
        instanceKey = key;
        return render();
      };
    }
    return createInstance;
  }
  function useScope(token2, defaultValue) {
    const scopedData = instanceScopes.get(instanceKey) || [];
    let scopedValue = void 0;
    if (scopedData.length) {
      scopedValue = getValue(scopedData, token2.split("."));
    }
    return scopedValue === void 0 ? defaultValue : scopedValue;
  }
  function slotData(data, key) {
    return new Proxy(data, {
      get(...args) {
        let data2 = void 0;
        const property = args[1];
        if (typeof property === "string") {
          const prevKey = instanceKey;
          instanceKey = key;
          data2 = useScope(property, void 0);
          instanceKey = prevKey;
        }
        return data2 !== void 0 ? data2 : Reflect.get(...args);
      }
    });
  }
  function createRenderFn(instanceCreator, data, instanceKey2) {
    return instanceCreator(
      (requirements, hints = {}) => {
        return requirements.reduce((tokens, token2) => {
          if (token2.startsWith("slots.")) {
            const slot = token2.substring(6);
            const hasSlot = () => data.slots && has(data.slots, slot) && typeof data.slots[slot] === "function";
            if (hints.if) {
              tokens[token2] = hasSlot;
            } else if (data.slots) {
              const scopedData = slotData(data, instanceKey2);
              tokens[token2] = () => hasSlot() ? data.slots[slot](scopedData) : null;
            }
          } else {
            const value = getRef(token2, data);
            tokens[token2] = () => useScope(token2, value.value);
          }
          return tokens;
        }, {});
      },
      instanceKey2
    );
  }
  function clean(schema, memoKey, instanceKey2) {
    memoKey ?? (memoKey = toMemoKey(schema));
    memoKeys[memoKey]--;
    if (memoKeys[memoKey] === 0) {
      delete memoKeys[memoKey];
      const [, providers] = memo[memoKey];
      delete memo[memoKey];
      providers.length = 0;
    }
    instanceScopes.delete(instanceKey2);
  }
  function toMemoKey(schema) {
    return JSON.stringify(schema, (_, value) => {
      if (typeof value === "function") {
        return value.toString();
      }
      return value;
    });
  }
  var FormKitSchema = /* @__PURE__ */ Vue.defineComponent({
    name: "FormKitSchema",
    props: {
      schema: {
        type: [Array, Object],
        required: true
      },
      data: {
        type: Object,
        default: () => ({})
      },
      library: {
        type: Object,
        default: () => ({})
      },
      memoKey: {
        type: String,
        required: false
      }
    },
    emits: ["mounted"],
    setup(props, context) {
      const instance = Vue.getCurrentInstance();
      let instanceKey2 = {};
      instanceScopes.set(instanceKey2, []);
      const library = { FormKit: Vue.markRaw(FormKit_default), ...props.library };
      let provider = parseSchema(library, props.schema, props.memoKey);
      let render;
      let data;
      if (!isServer2) {
        Vue.watch(
          () => props.schema,
          (newSchema, oldSchema) => {
            const oldKey = instanceKey2;
            instanceKey2 = {};
            instanceScopes.set(instanceKey2, []);
            provider = parseSchema(library, props.schema, props.memoKey);
            render = createRenderFn(provider, data, instanceKey2);
            if (newSchema === oldSchema) {
              (instance?.proxy?.$forceUpdate)();
            }
            clean(props.schema, props.memoKey, oldKey);
          },
          { deep: true }
        );
      }
      Vue.watchEffect(() => {
        data = Object.assign(Vue.reactive(props.data ?? {}), {
          slots: context.slots
        });
        context.slots;
        render = createRenderFn(provider, data, instanceKey2);
      });
      function cleanUp() {
        clean(props.schema, props.memoKey, instanceKey2);
        if (data) {
          if (data.node)
            data.node.destroy();
          data.slots = null;
          data = null;
        }
        render = null;
      }
      Vue.onMounted(() => context.emit("mounted"));
      Vue.onUnmounted(cleanUp);
      onSSRComplete(Vue.getCurrentInstance()?.appContext.app, cleanUp);
      return () => render ? render() : null;
    }
  });
  var FormKitSchema_default = FormKitSchema;

  // packages/vue/src/FormKit.ts
  init_dist3();
  var isServer3 = typeof window === "undefined";
  var parentSymbol = Symbol("FormKitParent");
  var componentSymbol = Symbol("FormKitComponentCallback");
  var currentSchemaNode = null;
  var getCurrentSchemaNode = () => currentSchemaNode;
  function FormKit(props, context) {
    const node = useInput(props, context);
    if (!node.props.definition)
      error(600, node);
    if (node.props.definition.component) {
      return () => Vue.h(
        node.props.definition?.component,
        {
          context: node.context
        },
        { ...context.slots }
      );
    }
    const schema = Vue.ref([]);
    let memoKey = node.props.definition.schemaMemoKey;
    const generateSchema = () => {
      const schemaDefinition = node.props?.definition?.schema;
      if (!schemaDefinition)
        error(601, node);
      if (typeof schemaDefinition === "function") {
        currentSchemaNode = node;
        schema.value = schemaDefinition({ ...props.sectionsSchema || {} });
        currentSchemaNode = null;
        if (memoKey && props.sectionsSchema || "memoKey" in schemaDefinition && typeof schemaDefinition.memoKey === "string") {
          memoKey = (memoKey ?? schemaDefinition?.memoKey) + JSON.stringify(props.sectionsSchema);
        }
      } else {
        schema.value = schemaDefinition;
      }
    };
    generateSchema();
    if (!isServer3) {
      node.on("schema", () => {
        memoKey += "♻️";
        generateSchema();
      });
    }
    context.emit("node", node);
    const definitionLibrary = node.props.definition.library;
    const library = {
      FormKit: Vue.markRaw(formkitComponent),
      ...definitionLibrary,
      ...props.library ?? {}
    };
    function didMount() {
      node.emit("mounted");
    }
    context.expose({ node });
    return () => Vue.h(
      FormKitSchema,
      {
        schema: schema.value,
        data: node.context,
        onMounted: didMount,
        library,
        memoKey
      },
      { ...context.slots }
    );
  }
  var formkitComponent = /* @__PURE__ */ Vue.defineComponent(
    FormKit,
    {
      props: runtimeProps,
      inheritAttrs: false
    }
  );
  var FormKit_default = formkitComponent;
  var rootSymbol = Symbol();
  var FormKitRoot = /* @__PURE__ */ Vue.defineComponent((_p, context) => {
    const boundary = Vue.ref(null);
    const showBody = Vue.ref(false);
    const shadowRoot = Vue.ref(void 0);
    const stopWatch2 = Vue.watch(boundary, (el) => {
      let parent = el;
      let root = null;
      while (parent = parent?.parentNode) {
        root = parent;
        if (root instanceof ShadowRoot || root instanceof Document) {
          foundRoot(root);
          break;
        }
      }
      stopWatch2();
      showBody.value = true;
    });
    Vue.provide(rootSymbol, shadowRoot);
    function foundRoot(root) {
      shadowRoot.value = root;
    }
    return () => showBody.value && context.slots.default ? context.slots.default() : Vue.h("template", { ref: boundary });
  });

  // packages/vue/src/composables/useInput.ts
  init_dist2();
  init_dist();

  // packages/vue/src/plugin.ts
  init_dist2();
  function createPlugin(app, options2) {
    app.component(options2.alias || "FormKit", FormKit_default).component(options2.schemaAlias || "FormKitSchema", FormKitSchema_default);
    return {
      get: getNode,
      setLocale: (locale) => {
        if (options2.config?.rootConfig) {
          options2.config.rootConfig.locale = locale;
        }
      },
      clearErrors: clearErrors2,
      setErrors: setErrors2,
      submit: submitForm,
      reset
    };
  }
  var optionsSymbol = Symbol.for("FormKitOptions");
  var configSymbol = Symbol.for("FormKitConfig");
  var plugin = {
    install(app, _options) {
      const options2 = Object.assign(
        {
          alias: "FormKit",
          schemaAlias: "FormKitSchema"
        },
        typeof _options === "function" ? _options() : _options
      );
      const rootConfig = createConfig(options2.config || {});
      options2.config = { rootConfig };
      app.config.globalProperties.$formkit = createPlugin(app, options2);
      app.provide(optionsSymbol, options2);
      app.provide(configSymbol, rootConfig);
      if (typeof window !== "undefined") {
        globalThis.__FORMKIT_CONFIGS__ = (globalThis.__FORMKIT_CONFIGS__ || []).concat([rootConfig]);
      }
    }
  };

  // packages/vue/src/composables/useInput.ts
  var isBrowser2 = typeof window !== "undefined";
  var pseudoProps = [
    // Boolean props
    "ignore",
    "disabled",
    "preserve",
    // String props
    "help",
    "label",
    /^preserve(-e|E)rrors/,
    /^[a-z]+(?:-visibility|Visibility|-behavior|Behavior)$/,
    /^[a-zA-Z-]+(?:-class|Class)$/,
    "prefixIcon",
    "suffixIcon",
    /^[a-zA-Z-]+(?:-icon|Icon)$/
  ];
  var boolProps = ["disabled", "ignore", "preserve"];
  function classesToNodeProps(node, props) {
    if (props.classes) {
      Object.keys(props.classes).forEach(
        (key) => {
          if (typeof key === "string") {
            node.props[`_${key}Class`] = props.classes[key];
            if (isObject(props.classes[key]) && key === "inner")
              Object.values(props.classes[key]);
          }
        }
      );
    }
  }
  function onlyListeners(props) {
    if (!props)
      return {};
    const knownListeners = ["Submit", "SubmitRaw", "SubmitInvalid"].reduce(
      (listeners, listener) => {
        const name = `on${listener}`;
        if (name in props) {
          if (typeof props[name] === "function") {
            listeners[name] = props[name];
          }
        }
        return listeners;
      },
      {}
    );
    return knownListeners;
  }
  function useInput(props, context, options2 = {}) {
    const config = Object.assign({}, Vue.inject(optionsSymbol) || {}, options2);
    const __root = Vue.inject(rootSymbol, Vue.ref(isBrowser2 ? document : void 0));
    const __cmpCallback = Vue.inject(componentSymbol, () => {
    });
    const instance = Vue.getCurrentInstance();
    const listeners = onlyListeners(instance?.vnode.props);
    const isVModeled = ["modelValue", "model-value"].some(
      (prop) => prop in (instance?.vnode.props ?? {})
    );
    let isMounted = false;
    Vue.onMounted(() => {
      isMounted = true;
    });
    const value = props.modelValue !== void 0 ? props.modelValue : cloneAny(context.attrs.value);
    function createInitialProps() {
      const initialProps2 = {
        ...nodeProps(props),
        ...listeners,
        type: props.type ?? "text",
        __root: __root.value,
        __slots: context.slots
      };
      const attrs = except(nodeProps(context.attrs), pseudoProps);
      if (!attrs.key)
        attrs.key = token();
      initialProps2.attrs = attrs;
      const propValues = only(nodeProps(context.attrs), pseudoProps);
      for (const propName in propValues) {
        if (boolProps.includes(propName) && propValues[propName] === "") {
          propValues[propName] = true;
        }
        initialProps2[camel(propName)] = propValues[propName];
      }
      const classesProps = { props: {} };
      classesToNodeProps(classesProps, props);
      Object.assign(initialProps2, classesProps.props);
      if (typeof initialProps2.type !== "string") {
        initialProps2.definition = initialProps2.type;
        delete initialProps2.type;
      }
      return initialProps2;
    }
    const initialProps = createInitialProps();
    const parent = initialProps.ignore ? null : props.parent || Vue.inject(parentSymbol, null);
    const node = createNode(
      extend(
        config || {},
        {
          name: props.name || void 0,
          value,
          parent,
          plugins: (config.plugins || []).concat(props.plugins ?? []),
          config: props.config || {},
          props: initialProps,
          index: props.index,
          sync: !!undefine(context.attrs.sync || context.attrs.dynamic)
        },
        false,
        true
      )
    );
    __cmpCallback(node);
    if (!node.props.definition)
      error(600, node);
    const lateBoundProps = Vue.ref(
      new Set(
        Array.isArray(node.props.__propDefs) ? node.props.__propDefs : Object.keys(node.props.__propDefs ?? {})
      )
    );
    node.on(
      "added-props",
      ({ payload: lateProps }) => {
        const propNames = Array.isArray(lateProps) ? lateProps : Object.keys(lateProps ?? {});
        propNames.forEach((newProp) => lateBoundProps.value.add(newProp));
      }
    );
    const pseudoPropNames = Vue.computed(
      () => pseudoProps.concat([...lateBoundProps.value]).reduce((names, prop) => {
        if (typeof prop === "string") {
          names.push(camel(prop));
          names.push(kebab(prop));
        } else {
          names.push(prop);
        }
        return names;
      }, [])
    );
    Vue.watchEffect(() => classesToNodeProps(node, props));
    const passThrough = nodeProps(props);
    for (const prop in passThrough) {
      Vue.watch(
        () => props[prop],
        () => {
          if (props[prop] !== void 0) {
            node.props[prop] = props[prop];
          }
        }
      );
    }
    Vue.watchEffect(() => {
      node.props.__root = __root.value;
    });
    const attributeWatchers = /* @__PURE__ */ new Set();
    const possibleProps = nodeProps(context.attrs);
    Vue.watchEffect(() => {
      watchAttributes(only(possibleProps, pseudoPropNames.value));
    });
    function watchAttributes(attrProps) {
      attributeWatchers.forEach((stop) => {
        stop();
        attributeWatchers.delete(stop);
      });
      for (const prop in attrProps) {
        const camelName = camel(prop);
        attributeWatchers.add(
          Vue.watch(
            () => context.attrs[prop],
            () => {
              node.props[camelName] = context.attrs[prop];
            }
          )
        );
      }
    }
    Vue.watchEffect(() => {
      const attrs = except(nodeProps(context.attrs), pseudoPropNames.value);
      if ("multiple" in attrs)
        attrs.multiple = undefine(attrs.multiple);
      if (typeof attrs.onBlur === "function") {
        attrs.onBlur = oncePerTick(attrs.onBlur);
      }
      node.props.attrs = Object.assign({}, node.props.attrs || {}, attrs);
    });
    Vue.watchEffect(() => {
      const messages4 = (props.errors ?? []).map(
        (error2) => /* @__PURE__ */ createMessage({
          key: slugify(error2),
          type: "error",
          value: error2,
          meta: { source: "prop" }
        })
      );
      node.store.apply(
        messages4,
        (message4) => message4.type === "error" && message4.meta.source === "prop"
      );
    });
    if (node.type !== "input") {
      const sourceKey = `${node.name}-prop`;
      Vue.watchEffect(() => {
        const inputErrors = props.inputErrors ?? {};
        const keys = Object.keys(inputErrors);
        if (!keys.length)
          node.clearErrors(true, sourceKey);
        const messages4 = keys.reduce((messages5, key) => {
          let value2 = inputErrors[key];
          if (typeof value2 === "string")
            value2 = [value2];
          if (Array.isArray(value2)) {
            messages5[key] = value2.map(
              (error2) => /* @__PURE__ */ createMessage({
                key: error2,
                type: "error",
                value: error2,
                meta: { source: sourceKey }
              })
            );
          }
          return messages5;
        }, {});
        node.store.apply(
          messages4,
          (message4) => message4.type === "error" && message4.meta.source === sourceKey
        );
      });
    }
    Vue.watchEffect(() => Object.assign(node.config, props.config));
    if (node.type !== "input") {
      Vue.provide(parentSymbol, node);
    }
    let clonedValueBeforeVmodel = void 0;
    node.on("modelUpdated", () => {
      context.emit("inputRaw", node.context?.value, node);
      if (isMounted) {
        context.emit("input", node.context?.value, node);
      }
      if (isVModeled && node.context) {
        clonedValueBeforeVmodel = cloneAny(node.value);
        context.emit("update:modelValue", shallowClone(node.value));
      }
    });
    if (isVModeled) {
      Vue.watch(
        Vue.toRef(props, "modelValue"),
        (value2) => {
          if (!eq(clonedValueBeforeVmodel, value2)) {
            node.input(value2, false);
          }
        },
        { deep: true }
      );
      if (node.value !== value) {
        node.emit("modelUpdated");
      }
    }
    Vue.onBeforeUnmount(() => node.destroy());
    return node;
  }

  // packages/vue/src/composables/createInput.ts
  init_dist();
  init_dist3();
  var totalCreated = 1;
  function isComponent2(obj) {
    return typeof obj === "function" && obj.length === 2 || typeof obj === "object" && !Array.isArray(obj) && !("$el" in obj) && !("$cmp" in obj) && !("if" in obj);
  }
  function createInput(schemaOrComponent, definitionOptions = {}, sectionsSchema = {}) {
    const definition3 = {
      type: "input",
      ...definitionOptions
    };
    let schema;
    if (isComponent2(schemaOrComponent)) {
      const cmpName = `SchemaComponent${totalCreated++}`;
      schema = createSection("input", () => ({
        $cmp: cmpName,
        props: {
          context: "$node.context"
        }
      }));
      definition3.library = { [cmpName]: Vue.markRaw(schemaOrComponent) };
    } else if (typeof schemaOrComponent === "function") {
      schema = schemaOrComponent;
    } else {
      schema = createSection("input", () => cloneAny(schemaOrComponent));
    }
    definition3.schema = useSchema(schema || "Schema undefined", sectionsSchema);
    if (!definition3.schemaMemoKey) {
      definition3.schemaMemoKey = `${Math.random()}`;
    }
    return definition3;
  }

  // packages/vue/src/composables/defineFormKitConfig.ts
  function defineFormKitConfig(config) {
    return () => typeof config === "function" ? config() : config;
  }
  init_dist2();
  var inputList = {};
  var schemas = {};
  var classes = {
    container: `
    formkit-kitchen-sink 
    p-8
  `,
    tabs: `
    formkit-tabs 
    mt-4 
    mr-[min(350px,25vw)]
  `,
    tab: `
    formkit-kitchen-sink-tab
    inline-block
    mb-4
    -mr-px
    cursor-pointer
    px-4
    py-2
    border
    border-neutral-200
    text-neutral-800
    data-[active]:bg-neutral-800
    data-[active]:border-neutral-800
    data-[active]:text-neutral-50
    hover:bg-neutral-100
    hover:text-neutral-900
    dark:border-neutral-700
    dark:text-neutral-50
    dark:data-[active]:bg-neutral-100
    dark:data-[active]:border-neutral-100
    dark:data-[active]:text-neutral-800
    dark:hover:bg-neutral-800
    dark:hover:text-neutral-50
  `,
    filterContainer: `
    formkit-filter-container
    grid
    grid-cols-[repeat(auto-fit,300px)]
    mr-[min(350px,25vw)]
    -mt-4
    mb-8
    px-4
    pt-8
    pb-4
    border
    relative
    -translate-y-px
    max-w-[1000px]
    border-neutral-200
    dark:border-neutral-700
  `,
    filterGroup: `
    formkit-filter-group
    mr-8
    mb-8
    [&_legend]:text-lg
    [&_ul]:columns-2
    [&_ul>li:first-child]:[column-span:all]
    [&_ul>li:first-child]:mt-2
    [&_ul>li:first-child]:mb-2
    [&_ul>li:first-child]:pb-2
    [&_ul>li:first-child]:border-b
    [&_ul>li:first-child]:border-neutral-200
    dark:[&_ul>li:first-child]:border-neutral-700
  `,
    formContainer: `
    formkit-form-container
    w-full
    bg-white
    rounded
    border
    border-neutral-100
    shadow-lg
    max-w-[800px]
    p-[min(5vw,5rem)]
    dark:bg-neutral-900
    dark:border-neutral-800
    dark:shadow-3xl
    [&_form>h1]:text-2xl
    [&_form>h1]:mb-4
    [&_form>h1]:font-bold
    [&_form>h1+p]:text-base
    [&_form>h1+p]:mb-4
    [&_form>h1+p]:-mt-2
    [&_form_.double]:flex
    [&_form_.double>*]:w-1/2
    [&_form_.double>*:first-child]:mr-2
    [&_form_.triple]:flex
    [&_form_.triple>*]:w-1/3
    [&_form_.triple>*:first-child]:mr-2
    [&_form_.triple>*:last-child]:ml-2
  `,
    inputs: `formkit-inputs`,
    specimen: `
    formkit-specimen 
    flex 
    flex-col 
    p-2 
    max-w-[75vw]
  `,
    inputSection: `
    group/section
    formkit-input-section 
    mr-[min(325px,25vw)]
  `,
    specimenGroup: `
    formkit-specimen-group
    grid
    mb-16
    grid-cols-[repeat(auto-fit,400px)]
    group-data-[type="transferlist"]/section:grid-cols-[repeat(auto-fit,650px)]
    group-data-[type="multi-step"]/section:grid-cols-[repeat(auto-fit,550px)]
  `,
    inputType: `
    formkit-input-type
    block
    font-bold
    text-neutral-900
    border-b
    border-neutral-100
    text-3xl
    mb-8
    pb-2
    capitalize
    dark:border-neutral-800 
    dark:text-neutral-50
  `
  };
  async function fetchInputList() {
    const response = await fetch(
      "https://raw.githubusercontent.com/formkit/input-schemas/master/index.json"
    );
    const json = await response.json();
    return json;
  }
  async function fetchInputSchema(input2) {
    try {
      const response = await fetch(
        `https://raw.githubusercontent.com/formkit/input-schemas/master/schemas/${input2}.json`
      );
      const json = await response.json();
      return json;
    } catch (error2) {
      console.error(error2);
    }
  }
  var FormKitKitchenSink = /* @__PURE__ */ Vue.defineComponent({
    name: "FormKitKitchenSink",
    props: {
      schemas: {
        type: Array,
        required: false
      },
      pro: {
        type: Boolean,
        default: true
      },
      addons: {
        type: Boolean,
        default: true
      },
      forms: {
        type: Boolean,
        default: true
      },
      navigation: {
        type: Boolean,
        default: true
      }
    },
    async setup(props) {
      Vue.onMounted(() => {
        const filterNode = getNode("filter-checkboxes");
        data.filters = Vue.computed(() => {
          if (!filterNode?.context)
            return [];
          const filters = filterNode.context.value;
          const filterValues = [];
          Object.keys(filters).forEach((key) => {
            filterValues.push(...filters[key]);
          });
          return filterValues;
        });
      });
      inputList = Object.keys(inputList).length ? inputList : await fetchInputList();
      const promises = [];
      const activeTab = Vue.ref("");
      const inputCheckboxes = Vue.computed(() => {
        const inputGroups = {
          core: { label: "Inputs", name: "core", inputs: inputList.core }
        };
        if (props.pro) {
          inputGroups.pro = {
            label: "Pro Inputs",
            name: "pro",
            inputs: inputList.pro
          };
        }
        if (props.addons) {
          inputGroups.addons = {
            label: "Add-ons",
            name: "addons",
            inputs: inputList.addons
          };
        }
        return inputGroups;
      });
      if (!props.schemas) {
        const coreInputPromises = inputList.core.map(async (schema) => {
          const response = await fetchInputSchema(schema);
          schemas[schema] = response;
        });
        promises.push(...coreInputPromises);
        if (props.forms) {
          const formsPromises = inputList.forms.map(async (schema) => {
            const schemaName = `form/${schema}`;
            const response = await fetchInputSchema(schemaName);
            schemas[schemaName] = response;
          });
          promises.push(...formsPromises);
        }
        if (props.pro) {
          const proInputPromises = inputList.pro.map(async (schema) => {
            const response = await fetchInputSchema(schema);
            schemas[schema] = response;
          });
          promises.push(...proInputPromises);
        }
        if (props.addons) {
          const addonPromises = inputList.addons.map(async (schema) => {
            const response = await fetchInputSchema(schema);
            schemas[schema] = response;
          });
          promises.push(...addonPromises);
        }
      } else {
        const schemaPromises = props.schemas.map(async (schema) => {
          const response = await fetchInputSchema(`${schema}`);
          schemas[`${schema}`] = response;
        });
        promises.push(...schemaPromises);
      }
      const selectAll = (node) => {
        let previousValue = [];
        let skip = false;
        if (node.props.type !== "checkbox")
          return;
        node.on("created", () => {
          const currentValue = node.value;
          if (Array.isArray(currentValue) && currentValue.length === 1 && currentValue[0] === "all") {
            node.input(
              node.props.options.map((option2) => {
                if (typeof option2 !== "string")
                  return option2.value;
                return option2;
              })
            );
          }
          previousValue = Array.isArray(node.value) ? node.value : [];
        });
        node.on("commit", ({ payload }) => {
          if (skip) {
            skip = false;
            return;
          }
          if (!Array.isArray(payload))
            return;
          const previousValueHadAll = previousValue.includes("all");
          const currentValueHasAll = payload.includes("all");
          if (!previousValueHadAll && currentValueHasAll) {
            const computedOptions = node.props.options.map(
              (option2) => {
                if (typeof option2 !== "string")
                  return option2.value;
                return option2;
              }
            );
            node.input(computedOptions);
            previousValue = computedOptions;
            return;
          }
          if (previousValueHadAll && !currentValueHasAll) {
            node.input([]);
            previousValue = [];
            return;
          }
          const valueMinusAll = payload.filter((value) => value !== "all");
          if (valueMinusAll.length < node.props.options.length - 1 && currentValueHasAll) {
            node.input(valueMinusAll);
            previousValue = valueMinusAll;
            skip = true;
            return;
          }
          if (valueMinusAll.length === node.props.options.length - 1 && !currentValueHasAll) {
            const computedOptions = node.props.options.map(
              (option2) => {
                if (typeof option2 !== "string")
                  return option2.value;
                return option2;
              }
            );
            node.input(computedOptions);
            previousValue = Array.isArray(node.value) ? node.value : [];
            return;
          }
        });
      };
      const data = Vue.reactive({
        twClasses: classes,
        basicOptions: Array.from({ length: 15 }, (_, i) => `Option ${i + 1}`),
        asyncLoader: async () => {
          return await new Promise(() => {
          });
        },
        paginatedLoader: async ({
          page,
          hasNextPage
        }) => {
          const base = (page - 1) * 10;
          hasNextPage();
          return Array.from({ length: 10 }, (_, i) => `Option ${base + i + 1}`);
        },
        formSubmitHandler: async (data2) => {
          await new Promise((resolve) => setTimeout(resolve, 1e3));
          alert("Form submitted (fake) — check console for data object");
          console.log("Form data:", data2);
        },
        includes: (array, value) => {
          if (!Array.isArray(array))
            return false;
          return array.includes(value);
        },
        checkboxPlugins: [selectAll],
        filters: []
      });
      await Promise.all(promises);
      const inputKeys = Object.keys(schemas);
      const formNames = inputKeys.map((key) => {
        if (key.startsWith("form/")) {
          switch (key) {
            case "form/tshirt":
              return {
                id: key,
                name: "Order Form"
              };
            default:
              const name = key.replace("form/", "");
              return {
                id: key,
                name: name.charAt(0).toUpperCase() + name.slice(1) + " Form"
              };
          }
        }
        return {
          id: key,
          name: ""
        };
      });
      const filteredFormNames = formNames.filter((form3) => form3.name !== "");
      const forms = inputKeys.filter((schema) => {
        return schema.startsWith("form/");
      });
      const inputs2 = inputKeys.filter(
        (schema) => !schema.startsWith("form/")
      );
      const tabs = [];
      if (inputs2.length) {
        tabs.push({
          id: "kitchen-sink",
          name: "Kitchen Sink"
        });
      }
      if (forms.length) {
        tabs.push(...filteredFormNames.sort((a, b) => a.name > b.name ? 1 : -1));
      }
      if (tabs.length) {
        activeTab.value = tabs[0].id;
      }
      const kitchenSinkRenders = Vue.computed(() => {
        inputs2.sort();
        const schemaDefinitions = inputs2.reduce(
          (schemaDefinitions2, inputName) => {
            const schemaDefinition = schemas[inputName];
            schemaDefinitions2.push({
              $el: "div",
              if: '$includes($filters, "' + inputName + '")',
              attrs: {
                key: inputName,
                class: "$twClasses.inputSection",
                "data-type": inputName
              },
              children: [
                {
                  $el: "h2",
                  attrs: {
                    class: "$twClasses.inputType"
                  },
                  children: inputName
                },
                {
                  $el: "div",
                  attrs: {
                    class: "$twClasses.specimenGroup"
                  },
                  children: [
                    ...(Array.isArray(schemaDefinition) ? schemaDefinition : [schemaDefinition]).map((specimen) => {
                      return {
                        $el: "div",
                        attrs: {
                          class: "$twClasses.specimen"
                        },
                        children: [specimen]
                      };
                    })
                  ]
                }
              ]
            });
            return schemaDefinitions2;
          },
          []
        );
        return Vue.h(
          Vue.KeepAlive,
          {},
          {
            default: () => {
              return activeTab.value === "kitchen-sink" ? Vue.h(FormKitSchema, { schema: schemaDefinitions, data }) : null;
            }
          }
        );
      });
      const formRenders = Vue.computed(() => {
        return filteredFormNames.map((form3) => {
          const schemaDefinition = schemas[form3.id];
          return Vue.h(
            "div",
            {
              key: form3.id
            },
            activeTab.value === form3.id ? [
              Vue.h(
                "div",
                {
                  class: classes.formContainer
                },
                [
                  Vue.h(FormKitSchema, {
                    schema: schemaDefinition[0],
                    data
                  })
                ]
              )
            ] : ""
          );
        }).filter((form3) => form3.children);
      });
      const tabBar = Vue.computed(() => {
        return Vue.h(
          "div",
          {
            key: "tab-bar",
            class: classes.tabs
          },
          tabs.map((tab) => {
            return Vue.h(
              "span",
              {
                class: classes.tab,
                key: tab.id,
                "data-tab": tab.id,
                "data-active": activeTab.value === tab.id || void 0,
                onClick: () => {
                  activeTab.value = tab.id;
                }
              },
              tab.name
            );
          })
        );
      });
      const filterCheckboxes = Vue.computed(() => {
        const createCheckboxSchema = (inputGroup) => {
          return {
            $el: "div",
            attrs: {
              class: "$twClasses.filterGroup"
            },
            children: [
              {
                $formkit: "checkbox",
                name: inputGroup.name,
                label: inputGroup.label,
                plugins: "$checkboxPlugins",
                value: ["all"],
                options: [
                  {
                    label: "All",
                    value: "all"
                  },
                  ...Array.isArray(inputGroup.inputs) ? inputGroup.inputs : []
                ]
              }
            ]
          };
        };
        const filterSchema = Vue.h(FormKitSchema, {
          key: "filter-checkboxes",
          data,
          schema: {
            $formkit: "group",
            id: "filter-checkboxes",
            children: [
              {
                $el: "div",
                attrs: {
                  class: "$twClasses.filterContainer"
                },
                children: Object.keys(inputCheckboxes.value).map((key) => {
                  const inputGroup = inputCheckboxes.value[key];
                  return createCheckboxSchema(inputGroup);
                })
              }
            ]
          }
        });
        return Vue.h(
          Vue.KeepAlive,
          {},
          {
            default: () => {
              if (!(tabs.find((tab) => tab.id === "kitchen-sink") && activeTab.value === "kitchen-sink")) {
                return null;
              }
              return filterSchema;
            }
          }
        );
      });
      return () => {
        return Vue.h(
          "div",
          {
            class: classes.container
          },
          [
            tabs.length > 1 ? tabBar.value : void 0,
            filterCheckboxes.value,
            ...formRenders.value,
            kitchenSinkRenders.value
          ]
        );
      };
    }
  });

  // packages/vue/src/FormKitMessages.ts
  init_dist3();
  init_dist();
  var messages2 = createSection("messages", () => ({
    $el: "ul",
    if: "$fns.length($messages)"
  }));
  var message2 = createSection("message", () => ({
    $el: "li",
    for: ["message", "$messages"],
    attrs: {
      key: "$message.key",
      id: `$id + '-' + $message.key`,
      "data-message-type": "$message.type"
    }
  }));
  var definition = messages2(message2("$message.value"));
  var FormKitMessages = /* @__PURE__ */ Vue.defineComponent({
    props: {
      node: {
        type: Object,
        required: false
      },
      sectionsSchema: {
        type: Object,
        default: {}
      },
      defaultPosition: {
        type: [String, Boolean],
        default: false
      },
      library: {
        type: Object,
        default: () => ({})
      }
    },
    setup(props, context) {
      const node = Vue.computed(() => {
        return props.node || Vue.inject(parentSymbol, void 0);
      });
      Vue.watch(
        node,
        () => {
          if (node.value?.context && !undefine(props.defaultPosition)) {
            node.value.context.defaultMessagePlacement = false;
          }
        },
        { immediate: true }
      );
      const schema = definition(props.sectionsSchema || {});
      const data = Vue.computed(() => {
        return {
          messages: node.value?.context?.messages || {},
          fns: node.value?.context?.fns || {},
          classes: node.value?.context?.classes || {}
        };
      });
      return () => node.value?.context ? Vue.h(
        FormKitSchema_default,
        { schema, data: data.value, library: props.library },
        { ...context.slots }
      ) : null;
    }
  });

  // packages/vue/src/FormKitProvider.ts
  init_dist2();
  function useConfig(config) {
    const options2 = Object.assign(
      {
        alias: "FormKit",
        schemaAlias: "FormKitSchema"
      },
      typeof config === "function" ? config() : config
    );
    const rootConfig = createConfig(options2.config || {});
    options2.config = { rootConfig };
    Vue.provide(optionsSymbol, options2);
    Vue.provide(configSymbol, rootConfig);
    if (typeof window !== "undefined") {
      globalThis.__FORMKIT_CONFIGS__ = (globalThis.__FORMKIT_CONFIGS__ || []).concat([rootConfig]);
    }
  }
  var FormKitProvider = /* @__PURE__ */ Vue.defineComponent(
    function FormKitProvider2(props, { slots, attrs }) {
      const options2 = {};
      if (props.config) {
        useConfig(props.config);
      }
      return () => slots.default ? slots.default(options2).map((vnode) => {
        return Vue.h(vnode, {
          ...attrs,
          ...vnode.props
        });
      }) : null;
    },
    { props: ["config"], name: "FormKitProvider", inheritAttrs: false }
  );
  var FormKitConfigLoader = /* @__PURE__ */ Vue.defineComponent(
    async function FormKitConfigLoader2(props, context) {
      let config = {};
      if (props.configFile) {
        const configFile = await import(
          /*@__formkit.config.ts__*/
          /* @vite-ignore */
          /* webpackIgnore: true */
          props.configFile
        );
        config = "default" in configFile ? configFile.default : configFile;
      }
      if (typeof config === "function") {
        config = config();
      }
      const useDefaultConfig = props.defaultConfig ?? true;
      if (useDefaultConfig) {
        const { defaultConfig: defaultConfig3 } = await Promise.resolve().then(() => (init_defaultConfig(), defaultConfig_exports));
        config = /* @__PURE__ */ defaultConfig3(config);
      }
      return () => Vue.h(FormKitProvider, { ...context.attrs, config }, context.slots);
    },
    {
      props: ["defaultConfig", "configFile"],
      inheritAttrs: false
    }
  );
  var FormKitLazyProvider = /* @__PURE__ */ Vue.defineComponent(
    function FormKitLazyProvider2(props, context) {
      const config = Vue.inject(optionsSymbol, null);
      const passthru = (vnode) => {
        return Vue.h(vnode, {
          ...context.attrs,
          ...vnode.props
        });
      };
      if (config) {
        return () => context.slots?.default ? context.slots.default().map(passthru) : null;
      }
      const instance = Vue.getCurrentInstance();
      if (instance.suspense) {
        return () => Vue.h(FormKitConfigLoader, props, {
          default: () => context.slots?.default ? context.slots.default().map(passthru) : null
        });
      }
      return () => Vue.h(Vue.Suspense, null, {
        ...context.slots,
        default: () => Vue.h(FormKitConfigLoader, { ...context.attrs, ...props }, context.slots)
      });
    },
    {
      props: ["defaultConfig", "configFile"],
      inheritAttrs: false
    }
  );

  // packages/vue/src/composables/useContext.ts
  init_dist2();
  function useFormKitContext(addressOrEffect, optionalEffect) {
    const address = typeof addressOrEffect === "string" ? addressOrEffect : void 0;
    const effect = typeof addressOrEffect === "function" ? addressOrEffect : optionalEffect;
    const context = Vue.ref();
    const parentNode = Vue.inject(parentSymbol, null);
    if (parentNode) {
      if (address) {
        context.value = parentNode.at(address)?.context;
        const root = parentNode.at("$root");
        if (root) {
          const receipt = root.on("child.deep", () => {
            const targetNode = parentNode.at(address);
            if (targetNode && targetNode.context !== context.value) {
              context.value = targetNode.context;
              if (effect)
                effect(context.value);
            }
          });
          Vue.onUnmounted(() => {
            root.off(receipt);
          });
        }
      } else {
        context.value = parentNode?.context;
      }
    }
    if (context.value && effect)
      effect(context.value);
    return context;
  }
  function useFormKitContextById(id, effect) {
    const context = Vue.ref();
    const targetNode = getNode(id);
    if (targetNode)
      context.value = targetNode.context;
    if (!targetNode) {
      const receipt = watchRegistry(id, ({ payload: node }) => {
        if (node) {
          context.value = node.context;
          stopWatch(receipt);
          if (effect)
            effect(context.value);
        }
      });
    }
    if (context.value && effect)
      effect(context.value);
    return context;
  }
  function useFormKitNodeById(id, effect) {
    const nodeRef = Vue.ref();
    const targetNode = getNode(id);
    if (targetNode)
      nodeRef.value = targetNode;
    if (!targetNode) {
      const receipt = watchRegistry(id, ({ payload: node }) => {
        if (node) {
          nodeRef.value = node;
          stopWatch(receipt);
          if (effect)
            effect(node);
        }
      });
    }
    if (nodeRef.value && effect)
      effect(nodeRef.value);
    return nodeRef;
  }

  // packages/vue/src/FormKitSummary.ts
  init_dist3();
  init_dist();
  init_dist3();
  var summary = createSection("summary", () => ({
    $el: "div",
    attrs: {
      "aria-live": "polite"
    }
  }));
  var summaryInner = createSection("summaryInner", () => ({
    $el: "div",
    if: "$summaries.length && $showSummaries"
  }));
  var messages3 = createSection("messages", () => ({
    $el: "ul",
    if: "$summaries.length && $showSummaries"
  }));
  var message3 = createSection("message", () => ({
    $el: "li",
    for: ["summary", "$summaries"],
    attrs: {
      key: "$summary.key",
      "data-message-type": "$summary.type"
    }
  }));
  var summaryHeader = createSection("summaryHeader", () => ({
    $el: "h2",
    attrs: {
      id: "$id"
    }
  }));
  var messageLink = createSection("messageLink", () => ({
    $el: "a",
    attrs: {
      id: "$summary.key",
      href: '$: "#" + $summary.id',
      onClick: "$jumpLink"
    }
  }));
  var definition2 = summary(
    summaryInner(
      summaryHeader("$summaryHeader"),
      messages3(message3(messageLink("$summary.message")))
    )
  );
  var FormKitSummary = /* @__PURE__ */ Vue.defineComponent({
    props: {
      node: {
        type: Object,
        required: false
      },
      forceShow: {
        type: Boolean,
        default: false
      },
      sectionsSchema: {
        type: Object,
        default: {}
      }
    },
    emits: {
      /* eslint-disable-next-line @typescript-eslint/no-unused-vars */
      show: (_summaries) => true
    },
    setup(props, context) {
      const id = `summary-${token()}`;
      const node = Vue.computed(() => {
        return props.node || Vue.inject(parentSymbol, void 0);
      });
      if (!node)
        throw new Error(
          "FormKitSummary must have a FormKit parent or use the node prop."
        );
      const summaryContexts = Vue.ref([]);
      const showSummaries = Vue.ref(false);
      const summaries = Vue.computed(() => {
        const summarizedMessages = [];
        summaryContexts.value.forEach((context2) => {
          for (const idx in context2.messages) {
            const message4 = context2.messages[idx];
            if (typeof message4.value !== "string")
              continue;
            summarizedMessages.push({
              message: message4.value,
              id: context2.id,
              key: `${context2.id}-${message4.key}`,
              type: message4.type
            });
          }
        });
        return summarizedMessages;
      });
      const addContexts = () => {
        summaryContexts.value = [];
        node.value?.walk(
          (child) => child.context && summaryContexts.value.push(child.context)
        );
      };
      node.value?.on("submit-raw", async () => {
        addContexts();
        if (summaries.value.length === 0)
          return;
        context.emit("show", summaries.value);
        showSummaries.value = true;
        await Vue.nextTick();
        if (typeof window !== "undefined") {
          document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
          if (summaries.value[0]) {
            document.getElementById(summaries.value[0].key)?.focus();
          }
        }
      });
      node.value?.on("child", addContexts);
      function jumpLink(e) {
        if (e.target instanceof HTMLAnchorElement) {
          e.preventDefault();
          const id2 = e.target.getAttribute("href")?.substring(1);
          if (id2) {
            document.getElementById(id2)?.scrollIntoView({ behavior: "smooth" });
            document.getElementById(id2)?.focus();
          }
        }
      }
      localize("summaryHeader", "There were errors in your form.")(node.value);
      const schema = definition2(props.sectionsSchema || {});
      const data = Vue.computed(() => {
        return {
          id,
          fns: node.value?.context?.fns || {},
          classes: node.value?.context?.classes || {},
          summaries: summaries.value,
          showSummaries: props.forceShow || showSummaries.value,
          summaryHeader: node.value?.context?.ui?.summaryHeader?.value || "",
          jumpLink
        };
      });
      return () => node.value?.context ? Vue.h(FormKitSchema_default, { schema, data: data.value }, { ...context.slots }) : null;
    }
  });

  // packages/vue/src/index.ts
  init_defaultConfig();
  init_bindings();
  init_dist8();
  var FormKitIcon = /* @__PURE__ */ Vue.defineComponent({
    name: "FormKitIcon",
    props: {
      icon: {
        type: String,
        default: ""
      },
      iconLoader: {
        type: Function,
        default: null
      },
      iconLoaderUrl: {
        type: Function,
        default: null
      }
    },
    setup(props) {
      const icon2 = Vue.ref(void 0);
      const config = Vue.inject(optionsSymbol, {});
      const parent = Vue.inject(parentSymbol, null);
      let iconHandler = void 0;
      function loadIcon() {
        if (!iconHandler || typeof iconHandler !== "function")
          return;
        const iconOrPromise = iconHandler(props.icon);
        if (iconOrPromise instanceof Promise) {
          iconOrPromise.then((iconValue) => {
            icon2.value = iconValue;
          });
        } else {
          icon2.value = iconOrPromise;
        }
      }
      if (props.iconLoader && typeof props.iconLoader === "function") {
        iconHandler = createIconHandler(props.iconLoader);
      } else if (parent && parent.props?.iconLoader) {
        iconHandler = createIconHandler(parent.props.iconLoader);
      } else if (props.iconLoaderUrl && typeof props.iconLoaderUrl === "function") {
        iconHandler = createIconHandler(iconHandler, props.iconLoaderUrl);
      } else {
        const iconPlugin = config?.plugins?.find((plugin2) => {
          return typeof plugin2.iconHandler === "function";
        });
        if (iconPlugin) {
          iconHandler = iconPlugin.iconHandler;
        }
      }
      Vue.watch(
        () => props.icon,
        () => {
          loadIcon();
        },
        { immediate: true }
      );
      return () => {
        if (props.icon && icon2.value) {
          return Vue.h("span", {
            class: "formkit-icon",
            innerHTML: icon2.value
          });
        }
        return null;
      };
    }
  });

  // packages/vue/src/utilities/resetCount.ts
  init_dist3();
  init_dist2();
  function resetCount2() {
    resetCounts();
    resetCount();
  }

  // packages/vue/src/index.ts
  init_dist2();
  init_dist7();

  exports.FormKit = FormKit_default;
  exports.FormKitIcon = FormKitIcon;
  exports.FormKitKitchenSink = FormKitKitchenSink;
  exports.FormKitLazyProvider = FormKitLazyProvider;
  exports.FormKitMessages = FormKitMessages;
  exports.FormKitProvider = FormKitProvider;
  exports.FormKitRoot = FormKitRoot;
  exports.FormKitSchema = FormKitSchema;
  exports.FormKitSummary = FormKitSummary;
  exports.changeLocale = changeLocale;
  exports.clearErrors = clearErrors2;
  exports.componentSymbol = componentSymbol;
  exports.configSymbol = configSymbol;
  exports.createInput = createInput;
  exports.defineFormKitConfig = defineFormKitConfig;
  exports.getCurrentSchemaNode = getCurrentSchemaNode;
  exports.onSSRComplete = onSSRComplete;
  exports.optionsSymbol = optionsSymbol;
  exports.parentSymbol = parentSymbol;
  exports.plugin = plugin;
  exports.reset = reset;
  exports.resetCount = resetCount2;
  exports.rootSymbol = rootSymbol;
  exports.setErrors = setErrors2;
  exports.ssrComplete = ssrComplete;
  exports.submitForm = submitForm;
  exports.useConfig = useConfig;
  exports.useFormKitContext = useFormKitContext;
  exports.useFormKitContextById = useFormKitContextById;
  exports.useFormKitNodeById = useFormKitNodeById;
  exports.useInput = useInput;

  return exports;

})({}, Vue);
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.iife.js.map