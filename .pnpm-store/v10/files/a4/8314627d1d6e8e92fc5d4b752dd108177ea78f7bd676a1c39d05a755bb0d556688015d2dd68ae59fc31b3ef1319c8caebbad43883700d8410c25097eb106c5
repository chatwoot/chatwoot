'use strict';

var utils = require('@formkit/utils');

// packages/core/src/dispatcher.ts
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
      listeners.get(event.name).forEach((wrapper) => {
        if (event.origin === node || wrapper.modifiers.includes("deep")) {
          wrapper.listener(event);
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
    const receipt = listener.receipt || utils.token();
    const wrapper = {
      modifiers,
      event,
      listener,
      receipt
    };
    listeners.has(event) ? listeners.get(event)[pos](wrapper) : listeners.set(event, [wrapper]);
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
            eventListeners.filter((wrapper) => wrapper.receipt !== receipt)
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
function emit(node, context, name, payload, bubble2 = true, meta) {
  context._e(node, {
    payload,
    name,
    bubble: bubble2,
    origin: node,
    meta
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

// packages/core/src/errors.ts
var errorHandler = createDispatcher();
errorHandler((error2, next) => {
  if (!error2.message)
    error2.message = String(`E${error2.code}`);
  return next(error2);
});
var warningHandler = createDispatcher();
warningHandler((warning, next) => {
  if (!warning.message)
    warning.message = String(`W${warning.code}`);
  const result = next(warning);
  if (console && typeof console.warn === "function")
    console.warn(result.message);
  return result;
});
function warn(code, data = {}) {
  warningHandler.dispatch({ code, data });
}
function error(code, data = {}) {
  throw Error(errorHandler.dispatch({ code, data }).message);
}
function createMessage(conf, node) {
  const m = {
    blocking: false,
    key: utils.token(),
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
var storeTraps = {
  apply: applyMessages,
  set: setMessage,
  remove: removeMessage,
  filter: filterMessages,
  reduce: reduceMessages,
  release: releaseBuffer,
  touch: touchMessages
};
function createStore(_buffer = false) {
  const messages = {};
  let node;
  let buffer = _buffer;
  let _b = [];
  const _m = /* @__PURE__ */ new Map();
  let _r = void 0;
  const store = new Proxy(messages, {
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
      if (utils.has(storeTraps, property)) {
        return storeTraps[property].bind(
          null,
          messages,
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
function setMessage(messageStore, store, node, message) {
  if (store.buffer) {
    store._b.push([[message]]);
    return store;
  }
  if (messageStore[message.key] !== message) {
    if (typeof message.value === "string" && message.meta.localize !== false) {
      const previous = message.value;
      message.value = node.t(message);
      if (message.value !== previous) {
        message.meta.locale = node.props.locale;
      }
    }
    const e = `message-${utils.has(messageStore, message.key) ? "updated" : "added"}`;
    messageStore[message.key] = Object.freeze(
      node.hook.message.dispatch(message)
    );
    node.emit(e, message);
  }
  return store;
}
function touchMessages(messageStore, store) {
  for (const key in messageStore) {
    const message = { ...messageStore[key] };
    store.set(message);
  }
}
function removeMessage(messageStore, store, node, key) {
  if (utils.has(messageStore, key)) {
    const message = messageStore[key];
    delete messageStore[key];
    node.emit("message-removed", message);
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
    const message = messageStore[key];
    if ((!type || message.type === type) && !callback(message)) {
      removeMessage(messageStore, store, node, key);
    }
  }
}
function reduceMessages(messageStore, _store, _node, reducer, accumulator) {
  for (const key in messageStore) {
    const message = messageStore[key];
    accumulator = reducer(accumulator, message);
  }
  return accumulator;
}
function applyMessages(_messageStore, store, node, messages, clear) {
  if (Array.isArray(messages)) {
    if (store.buffer) {
      store._b.push([messages, clear]);
      return;
    }
    const applied = new Set(
      messages.map((message) => {
        store.set(message);
        return message.key;
      })
    );
    if (typeof clear === "string") {
      store.filter(
        (message) => message.type !== clear || applied.has(message.key)
      );
    } else if (typeof clear === "function") {
      store.filter((message) => !clear(message) || applied.has(message.key));
    }
  } else {
    for (const address in messages) {
      const child = node.at(address);
      if (child) {
        child.store.apply(messages[address], clear);
      } else {
        missed(node, store, address, messages[address], clear);
      }
    }
  }
}
function createMessages(node, ...errors) {
  const sourceKey = `${node.name}-set`;
  const make = (error2) => /* @__PURE__ */ createMessage({
    key: utils.slugify(error2),
    type: "error",
    value: error2,
    meta: { source: sourceKey, autoClear: true }
  });
  return errors.filter((m) => !!m).map((errorSet) => {
    if (typeof errorSet === "string")
      errorSet = [errorSet];
    if (Array.isArray(errorSet)) {
      return errorSet.map((error2) => make(error2));
    } else {
      const errors2 = {};
      for (const key in errorSet) {
        if (Array.isArray(errorSet[key])) {
          errors2[key] = errorSet[key].map(
            (error2) => make(error2)
          );
        } else {
          errors2[key] = [make(errorSet[key])];
        }
      }
      return errors2;
    }
  });
}
function missed(node, store, address, messages, clear) {
  const misses = store._m;
  if (!misses.has(address))
    misses.set(address, []);
  if (!store._r)
    store._r = releaseMissed(node, store);
  misses.get(address)?.push([messages, clear]);
}
function releaseMissed(node, store) {
  return node.on(
    "child.deep",
    ({ payload: child }) => {
      store._m.forEach((misses, address) => {
        if (node.at(address) === child) {
          misses.forEach(([messages, clear]) => {
            child.store.apply(messages, clear);
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
  store._b.forEach(([messages, clear]) => store.apply(messages, clear));
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
      return utils.has(ledger, counterName) ? ledger[counterName].promise : Promise.resolve();
    },
    unmerge: (child) => merge(n, ledger, child, true),
    value(counterName) {
      return utils.has(ledger, counterName) ? ledger[counterName].count : 0;
    }
  };
}
function createCounter(node, ledger, counterName, condition, increment = 0) {
  condition = parseCondition(condition || counterName);
  if (!utils.has(ledger, counterName)) {
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

// packages/core/src/registry.ts
var registry = /* @__PURE__ */ new Map();
var reflected = /* @__PURE__ */ new Map();
var emit2 = createEmitter();
var receipts = [];
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
function resetRegistry() {
  registry.forEach((node) => {
    deregister(node);
  });
  receipts.forEach((receipt) => emit2.off(receipt));
}
function watchRegistry(id, callback) {
  const receipt = emit2.on(id, callback);
  receipts.push(receipt);
  return receipt;
}
function stopWatch(receipt) {
  emit2.off(receipt);
}

// packages/core/src/config.ts
function configChange(node, prop, value) {
  let usingFallback = true;
  !(prop in node.config._t) ? node.emit(`config:${prop}`, value, false) : usingFallback = false;
  if (!(prop in node.props)) {
    node.emit("prop", { prop, value });
    node.emit(`prop:${prop}`, value);
  }
  return usingFallback;
}
function createConfig(options = {}) {
  const nodes = /* @__PURE__ */ new Set();
  const target = {
    ...options,
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

// packages/core/src/submitForm.ts
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
      const message = n.store[key];
      if (message.type === "error" || message.type === "ui" && key === "incomplete") {
        n.store.remove(key);
      } else if (message.type === "state") {
        n.store.set({ ...message, value: false });
      }
    }
  };
  clear(node);
  node.walk(clear);
}
function reset(id, resetTo) {
  const node = typeof id === "string" ? getNode(id) : id;
  if (node) {
    const initial = (n) => utils.cloneAny(n.props.initial) || (n.type === "group" ? {} : n.type === "list" ? [] : void 0);
    node._e.pause(node);
    const resetValue2 = utils.cloneAny(resetTo);
    if (resetTo && !utils.empty(resetTo)) {
      node.props.initial = utils.isObject(resetValue2) ? utils.init(resetValue2) : resetValue2;
      node.props._init = node.props.initial;
    }
    node.input(initial(node), false);
    node.walk((child) => {
      if (child.type === "list" && child.sync)
        return;
      child.input(initial(child), false);
    });
    node.input(
      utils.empty(resetValue2) && resetValue2 ? resetValue2 : initial(node),
      false
    );
    const isDeepReset = node.type !== "input" && resetTo && !utils.empty(resetTo) && utils.isObject(resetTo);
    if (isDeepReset) {
      node.walk((child) => {
        child.props.initial = utils.isObject(child.value) ? utils.init(child.value) : child.value;
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

// packages/core/src/node.ts
var defaultConfig = {
  delimiter: ".",
  delay: 0,
  locale: "en",
  rootClasses: (key) => ({ [`formkit-${utils.kebab(key)}`]: true })
};
var useIndex = Symbol("index");
var valueRemoved = Symbol("removed");
var valueMoved = Symbol("moved");
var valueInserted = Symbol("inserted");
function isList(arg) {
  return arg.type === "list" && Array.isArray(arg._value);
}
function isNode(node) {
  return node && typeof node === "object" && node.__FKNode__ === true;
}
var invalidSetter = (node, _context, property) => {
  error(102, [node, property]);
};
var traps = {
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
  extend: trap(extend),
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
var nameCount = 0;
var idCount = 0;
function resetCount() {
  nameCount = 0;
  idCount = 0;
}
function names(children) {
  return children.reduce(
    (named, child) => Object.assign(named, { [child.name]: child }),
    {}
  );
}
function createName(options) {
  if (options.parent?.type === "list")
    return useIndex;
  return options.name || `${options.props?.type || "input"}_${++nameCount}`;
}
function createValue(options) {
  if (options.type === "group") {
    return utils.init(
      options.value && typeof options.value === "object" && !Array.isArray(options.value) ? options.value : {}
    );
  } else if (options.type === "list") {
    return utils.init(Array.isArray(options.value) ? options.value : []);
  }
  return options.value;
}
function input(node, context, value, async = true) {
  context._value = validateInput(node, node.hook.input.dispatch(value));
  node.emit("input", context._value);
  if (node.isCreated && node.type === "input" && utils.eq(context._value, context.value) && !node.props.mergeStrategy) {
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
      const childValue = child.type !== "input" || _value[child.name] && typeof _value[child.name] === "object" ? utils.init(_value[child.name]) : _value[child.name];
      if (!child.isSettled || (!utils.isObject(childValue) || child.props.mergeStrategy) && utils.eq(childValue, child._value))
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
function define(node, context, definition) {
  context.type = definition.type;
  const clonedDef = utils.clone(definition);
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
  if (definition.forceTypeProp) {
    if (node.props.type)
      node.props.originalType = node.props.type;
    context.props.type = definition.forceTypeProp;
  }
  if (definition.family) {
    context.props.family = definition.family;
  }
  if (definition.features) {
    definition.features.forEach((feature) => feature(node));
  }
  if (definition.props) {
    node.addProps(definition.props);
  }
  node.emit("defined", definition);
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
      const camelName = utils.camel(attr);
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
    const initial = utils.cloneAny(context._value);
    node.props.initial = node.type !== "input" ? utils.init(initial) : initial;
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
  return utils.extend(toPropsObj(props), toPropsObj(newProps));
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
    let preserve = utils.undefine(child.props.preserve);
    let parent = child.parent;
    while (preserve === void 0 && parent) {
      preserve = utils.undefine(parent.props.preserve);
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
function use(node, context, plugin, run = true, library = true) {
  if (Array.isArray(plugin) || plugin instanceof Set) {
    plugin.forEach((p) => use(node, context, p));
    return node;
  }
  if (!context.plugins.has(plugin)) {
    if (library && typeof plugin.library === "function")
      plugin.library(node);
    if (run && plugin(node) !== false) {
      context.plugins.add(plugin);
      node.children.forEach((child) => child.use(plugin));
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
  const matches = String(selector).match(/^(find)\((.*)\)$/);
  if (matches) {
    const [, action, argStr] = matches;
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
      if (!utils.eq(target[prop], value, false)) {
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
  const fragment = typeof key === "string" ? { key, value: key, type } : key;
  const value = node.hook.text.dispatch(fragment);
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
  const errors = node.hook.setErrors.dispatch({ localErrors, childErrors });
  createMessages(node, errors.localErrors, errors.childErrors).forEach(
    (errors2) => {
      node.store.apply(errors2, (message) => message.meta.source === sourceKey);
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
      child.store.filter((message) => {
        return !(message.type === "error" && message.meta && message.meta.source === sourceKey);
      });
    });
  }
  return node;
}
function createProps(initial) {
  const props = {
    initial: typeof initial === "object" ? utils.cloneAny(initial) : initial
  };
  let node;
  let isEmitting = true;
  let propDefs = {};
  return new Proxy(props, {
    get(...args) {
      const [_t, prop] = args;
      let val;
      if (utils.has(props, prop)) {
        val = Reflect.get(...args);
        if (propDefs[prop]?.boolean)
          val = utils.boolGetter(val);
      } else if (node && typeof prop === "string" && node.config[prop] !== void 0) {
        val = node.config[prop];
        if (prop === "mergeStrategy" && node?.type === "input" && utils.isRecord(val) && node.name in val) {
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
      if (!utils.eq(props[prop], value, false) || typeof value === "object") {
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
function extend(node, context, property, trap2) {
  context.traps.set(property, trap2);
  return node;
}
function findDefinition(node, plugins) {
  if (node.props.definition)
    return node.define(node.props.definition);
  for (const plugin of plugins) {
    if (node.props.definition)
      return;
    if (typeof plugin.library === "function") {
      plugin.library(node);
    }
  }
}
function createContext(options) {
  const value = createValue(options);
  const config = createConfig2(options.config || {}, options.parent);
  return {
    _d: 0,
    _e: createEmitter(),
    uid: Symbol(),
    _resolve: false,
    _tmo: false,
    _value: value,
    children: utils.dedupe(options.children || []),
    config,
    hook: createHooks(),
    isCreated: false,
    isSettled: true,
    ledger: createLedger(),
    name: createName(options),
    parent: options.parent || null,
    plugins: /* @__PURE__ */ new Set(),
    props: createProps(value),
    settled: Promise.resolve(value),
    store: createStore(true),
    sync: options.sync || false,
    traps: createTraps(),
    type: options.type || "input",
    value
  };
}
function nodeInit(node, options) {
  const hasInitialId = options.props?.id;
  if (!hasInitialId)
    delete options.props?.id;
  node.ledger.init(node.store._n = node.props._n = node.config._n = node);
  node.props._emit = false;
  Object.assign(
    node.props,
    hasInitialId ? {} : { id: `input_${idCount++}` },
    options.props ?? {}
  );
  node.props._emit = true;
  findDefinition(
    node,
    /* @__PURE__ */ new Set([
      ...options.plugins || [],
      ...node.parent ? node.parent.plugins : []
    ])
  );
  if (options.plugins) {
    for (const plugin of options.plugins) {
      use(node, node._c, plugin, true, false);
    }
  }
  node.each((child) => node.add(child));
  if (node.parent)
    node.parent.add(node, options.index);
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
function createPlaceholder(options) {
  return {
    __FKP: true,
    uid: Symbol(),
    name: options?.name ?? `p_${nameCount++}`,
    value: options?.value ?? null,
    _value: options?.value ?? null,
    type: options?.type ?? "input",
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
function createNode(options) {
  const ops = options || {};
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
  return typeof node !== "string" && utils.has(node, "$el");
}
function isComponent(node) {
  return typeof node !== "string" && utils.has(node, "$cmp");
}
function isConditional(node) {
  if (!node || typeof node === "string")
    return false;
  return utils.has(node, "if") && utils.has(node, "then");
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
    return candidates.find((symbol) => {
      if (expression.length >= p + symbol.length) {
        const nextChars = expression.substring(p, p + symbol.length);
        if (nextChars === symbol)
          return symbol;
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
    const length = expression.length;
    let depth = 0;
    for (let p = pos; p < length; p++) {
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
    const length = expression.length;
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
    for (let p = 0; p < length; p++) {
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
        const args = utils.parseArgs(String(operand)).map(
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
                    const value = utils.getAt(userFuncReturn, token3);
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
      if (utils.isQuotedString(operand))
        return utils.rmEscapes(operand.substring(1, operand.length - 1));
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
  function provide(callback) {
    provideTokens = callback;
    return Object.assign(
      // @ts-ignore - @rollup/plugin-typescript doesn't like this
      compiled.bind(null, callback(reqs)),
      { provide }
    );
  }
  return Object.assign(compiled, {
    provide
  });
}

// packages/core/src/classes.ts
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

// packages/core/src/setErrors.ts
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

// packages/core/src/index.ts
var FORMKIT_VERSION = "1.6.7";

exports.FORMKIT_VERSION = FORMKIT_VERSION;
exports.bfs = bfs;
exports.clearErrors = clearErrors2;
exports.compile = compile;
exports.createClasses = createClasses;
exports.createConfig = createConfig;
exports.createMessage = createMessage;
exports.createNode = createNode;
exports.createPlaceholder = createPlaceholder;
exports.createValue = createValue;
exports.deregister = deregister;
exports.error = error;
exports.errorHandler = errorHandler;
exports.generateClassList = generateClassList;
exports.getNode = getNode;
exports.isComponent = isComponent;
exports.isConditional = isConditional;
exports.isDOM = isDOM;
exports.isList = isList;
exports.isNode = isNode;
exports.isPlaceholder = isPlaceholder;
exports.isSugar = isSugar;
exports.names = names;
exports.register = register;
exports.reset = reset;
exports.resetCount = resetCount;
exports.resetRegistry = resetRegistry;
exports.setErrors = setErrors2;
exports.stopWatch = stopWatch;
exports.submitForm = submitForm;
exports.sugar = sugar;
exports.use = use;
exports.useIndex = useIndex;
exports.valueInserted = valueInserted;
exports.valueMoved = valueMoved;
exports.valueRemoved = valueRemoved;
exports.warn = warn;
exports.warningHandler = warningHandler;
exports.watchRegistry = watchRegistry;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map