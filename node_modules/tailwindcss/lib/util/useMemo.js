"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.useMemo = useMemo;

function useMemo(cb, keyResolver) {
  const cache = new Map();
  return (...args) => {
    const key = keyResolver(...args);

    if (cache.has(key)) {
      return cache.get(key);
    }

    const result = cb(...args);
    cache.set(key, result);
    return result;
  };
}