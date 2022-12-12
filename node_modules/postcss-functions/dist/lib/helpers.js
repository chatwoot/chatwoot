'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isPromise = isPromise;
exports.hasPromises = hasPromises;
exports.then = then;
function isPromise(obj) {
  return !!obj && (typeof obj === 'object' || typeof obj === 'function') && typeof obj.then === 'function';
}

function hasPromises(arr) {
  return arr.some(function (item) {
    return isPromise(item);
  });
}

function then(promiseOrResult, onFulfilled) {
  if (isPromise(promiseOrResult)) return promiseOrResult.then(onFulfilled);

  return onFulfilled(promiseOrResult);
}