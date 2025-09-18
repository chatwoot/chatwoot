'use strict';

var utils = require('@formkit/utils');
var core = require('@formkit/core');

// packages/observer/src/index.ts
var revokedObservers = /* @__PURE__ */ new WeakSet();
function createObserver(node, dependencies) {
  const deps = dependencies || Object.assign(/* @__PURE__ */ new Map(), { active: false });
  const receipts = /* @__PURE__ */ new Map();
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
    if (core.isNode(value)) {
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
          return (block, after, pos) => watch(observed, block, after, pos);
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
          return receipts;
        case "kill":
          return () => {
            removeListeners(receipts);
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
        if (nodeReceipts && utils.has(nodeReceipts, event)) {
          nodeReceipts[event].map(depNode.off);
          delete nodeReceipts[event];
          node.receipts.set(depNode, nodeReceipts);
        }
      }
    });
  });
}
function removeListeners(receipts) {
  receipts.forEach((events, node) => {
    for (const event in events) {
      events[event].map(node.off);
    }
  });
  receipts.clear();
}
function watch(node, block, after, pos) {
  const doAfterObservation = (res2) => {
    const newDeps = node.stopObserve();
    applyListeners(
      node,
      diffDeps(oldDeps, newDeps),
      () => watch(node, block, after, pos),
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

exports.applyListeners = applyListeners;
exports.createObserver = createObserver;
exports.diffDeps = diffDeps;
exports.isKilled = isKilled;
exports.removeListeners = removeListeners;
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.cjs.map