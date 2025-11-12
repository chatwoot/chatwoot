var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => {
  __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);
  return value;
};
var __accessCheck = (obj, member, msg) => {
  if (!member.has(obj))
    throw TypeError("Cannot " + msg);
};
var __privateGet = (obj, member, getter) => {
  __accessCheck(obj, member, "read from private field");
  return getter ? getter.call(obj) : member.get(obj);
};
var __privateAdd = (obj, member, value) => {
  if (member.has(obj))
    throw TypeError("Cannot add the same private member more than once");
  member instanceof WeakSet ? member.add(obj) : member.set(obj, value);
};
var __privateSet = (obj, member, value, setter) => {
  __accessCheck(obj, member, "write to private field");
  setter ? setter.call(obj, value) : member.set(obj, value);
  return value;
};

// node_modules/.pnpm/tsup@5.12.9_w42fuc5ytk33cxmvw2eywssbqm/node_modules/tsup/assets/esm_shims.js
import { fileURLToPath } from "url";
import path from "path";
var getFilename = () => fileURLToPath(import.meta.url);
var getDirname = () => path.dirname(getFilename());
var __dirname = /* @__PURE__ */ getDirname();

// src/common.ts
var kMovable = Symbol("Tinypool.kMovable");
var kTransferable = Symbol.for("Tinypool.transferable");
var kValue = Symbol.for("Tinypool.valueOf");
var kQueueOptions = Symbol.for("Tinypool.queueOptions");
function isTransferable(value) {
  return value != null && typeof value === "object" && kTransferable in value && kValue in value;
}
function isMovable(value) {
  return isTransferable(value) && value[kMovable] === true;
}
function markMovable(value) {
  Object.defineProperty(value, kMovable, {
    enumerable: false,
    configurable: true,
    writable: true,
    value: true
  });
}
function isTaskQueue(value) {
  return typeof value === "object" && value !== null && "size" in value && typeof value.shift === "function" && typeof value.remove === "function" && typeof value.push === "function";
}
var kRequestCountField = 0;
var kResponseCountField = 1;
var kFieldCount = 2;

export {
  __publicField,
  __privateGet,
  __privateAdd,
  __privateSet,
  __dirname,
  kTransferable,
  kValue,
  kQueueOptions,
  isTransferable,
  isMovable,
  markMovable,
  isTaskQueue,
  kRequestCountField,
  kResponseCountField,
  kFieldCount
};
