var _contains = require('./_contains');


// A simple Set type that honours R.equals semantics
module.exports = (function() {
  function _Set() {
    /* globals Set */
    this._nativeSet = typeof Set === 'function' ? new Set() : null;
    this._items = {};
  }

  _Set.prototype.add = function(item) {
    return hasOrAdd(item, true, this);
  };

  _Set.prototype.has = function(item) {
    return hasOrAdd(item, false, this);
  };

  /**
   * Combines the logic for checking whether an item is a member of the set and
   * for adding a new item to the set.
   *
   * @param item       The item to check or add to the Set instance.
   * @param shouldAdd  If true, the item will be added to the set if it doesn't
   *                   already exist.
   * @param set        The set instance to check or add to.
   * @return {boolean} When shouldAdd is true, this will return true when a new
   *                   item was added otherwise false. When shouldAdd is false,
   *                   this will return true if the item already exists, otherwise
   *                   false.
   */
  function hasOrAdd(item, shouldAdd, set) {
    var type = typeof item;
    var prevSize, newSize;
    switch (type) {
      case 'string':
      case 'number':
        // distinguish between +0 and -0
        if (item === 0 && !set._items['-0'] && 1 / item === -Infinity) {
          if (shouldAdd) {
            set._items['-0'] = true;
          }
          return shouldAdd;
        }
        // these types can all utilise Set
        if (set._nativeSet !== null) {
          if (shouldAdd) {
            prevSize = set._nativeSet.size;
            set._nativeSet.add(item);
            newSize = set._nativeSet.size;
            return (newSize > prevSize);
          } else {
            return set._nativeSet.has(item);
          }
        } else {
          if (!(type in set._items)) {
            if (shouldAdd) {
              set._items[type] = {};
              set._items[type][item] = true;
            }
            return shouldAdd;
          } else if (item in set._items[type]) {
            return !shouldAdd;
          } else {
            if (shouldAdd) {
              set._items[type][item] = true;
            }
            return shouldAdd;
          }
        }

      case 'boolean':
        // set._items['boolean'] holds a two element array
        // representing [ falseExists, trueExists ]
        if (type in set._items) {
          var bIdx = item ? 1 : 0;
          if (set._items[type][bIdx]) {
            return !shouldAdd;
          } else {
            if (shouldAdd) {
              set._items[type][bIdx] = true;
            }
            return shouldAdd;
          }
        } else {
          if (shouldAdd) {
            set._items[type] = item ? [false, true] : [true, false];
          }
          return shouldAdd;
        }

      case 'function':
        // compare functions for reference equality
        if (set._nativeSet !== null) {
          if (shouldAdd) {
            prevSize = set._nativeSet.size;
            set._nativeSet.add(item);
            newSize = set._nativeSet.size;
            return (newSize > prevSize);
          } else {
            return set._nativeSet.has(item);
          }
        } else {
          if (!(type in set._items)) {
            if (shouldAdd) {
              set._items[type] = [item];
            }
            return shouldAdd;
          }
          if (!_contains(item, set._items[type])) {
            if (shouldAdd) {
              set._items[type].push(item);
            }
            return shouldAdd;
          }
        }
        return !shouldAdd;

      case 'undefined':
        if (set._items[type]) {
          return !shouldAdd;
        } else {
          if (shouldAdd) {
            set._items[type] = true;
          }
          return shouldAdd;
        }

      case 'object':
        if (item === null) {
          if (!set._items['null']) {
            if (shouldAdd) {
              set._items['null'] = true;
            }
            return shouldAdd;
          }
          return !shouldAdd;
        }
      /* falls through */
      default:
        // reduce the search size of heterogeneous sets by creating buckets
        // for each type.
        type = Object.prototype.toString.call(item);
        if (!(type in set._items)) {
          if (shouldAdd) {
            set._items[type] = [item];
          }
          return shouldAdd;
        }
        // scan through all previously applied items
        if (!_contains(item, set._items[type])) {
          if (shouldAdd) {
            set._items[type].push(item);
          }
          return shouldAdd;
        }
        return !shouldAdd;
    }
  }
  return _Set;
}());
