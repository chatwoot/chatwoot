/**
 * Creates a cache that evicts keys in fifo order
 * @param size {Number}
 */
function makeFifoCache(
  size,
)

 {
  // Maintain a fifo queue of keys, we cannot rely on Object.keys as the browser may not support it.
  let evictionOrder = [];
  let cache = {};

  return {
    add(key, value) {
      while (evictionOrder.length >= size) {
        // shift is O(n) but this is small size and only happens if we are
        // exceeding the cache size so it should be fine.
        const evictCandidate = evictionOrder.shift();

        if (evictCandidate !== undefined) {
          // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
          delete cache[evictCandidate];
        }
      }

      // in case we have a collision, delete the old key.
      if (cache[key]) {
        this.delete(key);
      }

      evictionOrder.push(key);
      cache[key] = value;
    },
    clear() {
      cache = {};
      evictionOrder = [];
    },
    get(key) {
      return cache[key];
    },
    size() {
      return evictionOrder.length;
    },
    // Delete cache key and return true if it existed, false otherwise.
    delete(key) {
      if (!cache[key]) {
        return false;
      }

      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete cache[key];

      for (let i = 0; i < evictionOrder.length; i++) {
        if (evictionOrder[i] === key) {
          evictionOrder.splice(i, 1);
          break;
        }
      }

      return true;
    },
  };
}

export { makeFifoCache };
//# sourceMappingURL=cache.js.map
