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
