'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.emptyObject = emptyObject;
exports.isOneline = exports.isError = exports.partition = exports.sparseArrayEquality = exports.typeEquality = exports.subsetEquality = exports.iterableEquality = exports.getObjectSubset = exports.getPath = void 0;

var _jestGetType = require('jest-get-type');

var _jasmineUtils = require('./jasmineUtils');

var Symbol = global['jest-symbol-do-not-touch'] || global.Symbol;

/**
 * Checks if `hasOwnProperty(object, key)` up the prototype chain, stopping at `Object.prototype`.
 */
const hasPropertyInObject = (object, key) => {
  const shouldTerminate =
    !object || typeof object !== 'object' || object === Object.prototype;

  if (shouldTerminate) {
    return false;
  }

  return (
    Object.prototype.hasOwnProperty.call(object, key) ||
    hasPropertyInObject(Object.getPrototypeOf(object), key)
  );
};

const getPath = (object, propertyPath) => {
  if (!Array.isArray(propertyPath)) {
    propertyPath = propertyPath.split('.');
  }

  if (propertyPath.length) {
    const lastProp = propertyPath.length === 1;
    const prop = propertyPath[0];
    const newObject = object[prop];

    if (!lastProp && (newObject === null || newObject === undefined)) {
      // This is not the last prop in the chain. If we keep recursing it will
      // hit a `can't access property X of undefined | null`. At this point we
      // know that the chain has broken and we can return right away.
      return {
        hasEndProp: false,
        lastTraversedObject: object,
        traversedPath: []
      };
    }

    const result = getPath(newObject, propertyPath.slice(1));

    if (result.lastTraversedObject === null) {
      result.lastTraversedObject = object;
    }

    result.traversedPath.unshift(prop);

    if (lastProp) {
      // Does object have the property with an undefined value?
      // Although primitive values support bracket notation (above)
      // they would throw TypeError for in operator (below).
      result.hasEndProp =
        newObject !== undefined ||
        (!(0, _jestGetType.isPrimitive)(object) && prop in object);

      if (!result.hasEndProp) {
        result.traversedPath.shift();
      }
    }

    return result;
  }

  return {
    lastTraversedObject: null,
    traversedPath: [],
    value: object
  };
}; // Strip properties from object that are not present in the subset. Useful for
// printing the diff for toMatchObject() without adding unrelated noise.

/* eslint-disable @typescript-eslint/explicit-module-boundary-types */

exports.getPath = getPath;

const getObjectSubset = (object, subset, seenReferences = new WeakMap()) => {
  /* eslint-enable @typescript-eslint/explicit-module-boundary-types */
  if (Array.isArray(object)) {
    if (Array.isArray(subset) && subset.length === object.length) {
      // The map method returns correct subclass of subset.
      return subset.map((sub, i) => getObjectSubset(object[i], sub));
    }
  } else if (object instanceof Date) {
    return object;
  } else if (isObject(object) && isObject(subset)) {
    if (
      (0, _jasmineUtils.equals)(object, subset, [
        iterableEquality,
        subsetEquality
      ])
    ) {
      // Avoid unnecessary copy which might return Object instead of subclass.
      return subset;
    }

    const trimmed = {};
    seenReferences.set(object, trimmed);
    Object.keys(object)
      .filter(key => hasPropertyInObject(subset, key))
      .forEach(key => {
        trimmed[key] = seenReferences.has(object[key])
          ? seenReferences.get(object[key])
          : getObjectSubset(object[key], subset[key], seenReferences);
      });

    if (Object.keys(trimmed).length > 0) {
      return trimmed;
    }
  }

  return object;
};

exports.getObjectSubset = getObjectSubset;
const IteratorSymbol = Symbol.iterator;

const hasIterator = object => !!(object != null && object[IteratorSymbol]);
/* eslint-disable @typescript-eslint/explicit-module-boundary-types */

const iterableEquality = (
  a,
  b,
  /* eslint-enable @typescript-eslint/explicit-module-boundary-types */
  aStack = [],
  bStack = []
) => {
  if (
    typeof a !== 'object' ||
    typeof b !== 'object' ||
    Array.isArray(a) ||
    Array.isArray(b) ||
    !hasIterator(a) ||
    !hasIterator(b)
  ) {
    return undefined;
  }

  if (a.constructor !== b.constructor) {
    return false;
  }

  let length = aStack.length;

  while (length--) {
    // Linear search. Performance is inversely proportional to the number of
    // unique nested structures.
    // circular references at same depth are equal
    // circular reference is not equal to non-circular one
    if (aStack[length] === a) {
      return bStack[length] === b;
    }
  }

  aStack.push(a);
  bStack.push(b);

  const iterableEqualityWithStack = (a, b) =>
    iterableEquality(a, b, [...aStack], [...bStack]);

  if (a.size !== undefined) {
    if (a.size !== b.size) {
      return false;
    } else if (
      (0, _jasmineUtils.isA)('Set', a) ||
      (0, _jasmineUtils.isImmutableUnorderedSet)(a)
    ) {
      let allFound = true;

      for (const aValue of a) {
        if (!b.has(aValue)) {
          let has = false;

          for (const bValue of b) {
            const isEqual = (0, _jasmineUtils.equals)(aValue, bValue, [
              iterableEqualityWithStack
            ]);

            if (isEqual === true) {
              has = true;
            }
          }

          if (has === false) {
            allFound = false;
            break;
          }
        }
      } // Remove the first value from the stack of traversed values.

      aStack.pop();
      bStack.pop();
      return allFound;
    } else if (
      (0, _jasmineUtils.isA)('Map', a) ||
      (0, _jasmineUtils.isImmutableUnorderedKeyed)(a)
    ) {
      let allFound = true;

      for (const aEntry of a) {
        if (
          !b.has(aEntry[0]) ||
          !(0, _jasmineUtils.equals)(aEntry[1], b.get(aEntry[0]), [
            iterableEqualityWithStack
          ])
        ) {
          let has = false;

          for (const bEntry of b) {
            const matchedKey = (0, _jasmineUtils.equals)(aEntry[0], bEntry[0], [
              iterableEqualityWithStack
            ]);
            let matchedValue = false;

            if (matchedKey === true) {
              matchedValue = (0, _jasmineUtils.equals)(aEntry[1], bEntry[1], [
                iterableEqualityWithStack
              ]);
            }

            if (matchedValue === true) {
              has = true;
            }
          }

          if (has === false) {
            allFound = false;
            break;
          }
        }
      } // Remove the first value from the stack of traversed values.

      aStack.pop();
      bStack.pop();
      return allFound;
    }
  }

  const bIterator = b[IteratorSymbol]();

  for (const aValue of a) {
    const nextB = bIterator.next();

    if (
      nextB.done ||
      !(0, _jasmineUtils.equals)(aValue, nextB.value, [
        iterableEqualityWithStack
      ])
    ) {
      return false;
    }
  }

  if (!bIterator.next().done) {
    return false;
  } // Remove the first value from the stack of traversed values.

  aStack.pop();
  bStack.pop();
  return true;
};

exports.iterableEquality = iterableEquality;

const isObject = a => a !== null && typeof a === 'object';

const isObjectWithKeys = a =>
  isObject(a) &&
  !(a instanceof Error) &&
  !(a instanceof Array) &&
  !(a instanceof Date);

const subsetEquality = (object, subset) => {
  // subsetEquality needs to keep track of the references
  // it has already visited to avoid infinite loops in case
  // there are circular references in the subset passed to it.
  const subsetEqualityWithContext = (seenReferences = new WeakMap()) => (
    object,
    subset
  ) => {
    if (!isObjectWithKeys(subset)) {
      return undefined;
    }

    return Object.keys(subset).every(key => {
      if (isObjectWithKeys(subset[key])) {
        if (seenReferences.has(subset[key])) {
          return (0, _jasmineUtils.equals)(object[key], subset[key], [
            iterableEquality
          ]);
        }

        seenReferences.set(subset[key], true);
      }

      const result =
        object != null &&
        hasPropertyInObject(object, key) &&
        (0, _jasmineUtils.equals)(object[key], subset[key], [
          iterableEquality,
          subsetEqualityWithContext(seenReferences)
        ]); // The main goal of using seenReference is to avoid circular node on tree.
      // It will only happen within a parent and its child, not a node and nodes next to it (same level)
      // We should keep the reference for a parent and its child only
      // Thus we should delete the reference immediately so that it doesn't interfere
      // other nodes within the same level on tree.

      seenReferences.delete(subset[key]);
      return result;
    });
  };

  return subsetEqualityWithContext()(object, subset);
}; // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types

exports.subsetEquality = subsetEquality;

const typeEquality = (a, b) => {
  if (a == null || b == null || a.constructor === b.constructor) {
    return undefined;
  }

  return false;
};

exports.typeEquality = typeEquality;

const sparseArrayEquality = (a, b) => {
  if (!Array.isArray(a) || !Array.isArray(b)) {
    return undefined;
  } // A sparse array [, , 1] will have keys ["2"] whereas [undefined, undefined, 1] will have keys ["0", "1", "2"]

  const aKeys = Object.keys(a);
  const bKeys = Object.keys(b);
  return (
    (0, _jasmineUtils.equals)(a, b, [iterableEquality, typeEquality], true) &&
    (0, _jasmineUtils.equals)(aKeys, bKeys)
  );
};

exports.sparseArrayEquality = sparseArrayEquality;

const partition = (items, predicate) => {
  const result = [[], []];
  items.forEach(item => result[predicate(item) ? 0 : 1].push(item));
  return result;
}; // Copied from https://github.com/graingert/angular.js/blob/a43574052e9775cbc1d7dd8a086752c979b0f020/src/Angular.js#L685-L693

exports.partition = partition;

const isError = value => {
  switch (Object.prototype.toString.call(value)) {
    case '[object Error]':
      return true;

    case '[object Exception]':
      return true;

    case '[object DOMException]':
      return true;

    default:
      return value instanceof Error;
  }
};

exports.isError = isError;

function emptyObject(obj) {
  return obj && typeof obj === 'object' ? !Object.keys(obj).length : false;
}

const MULTILINE_REGEXP = /[\r\n]/;

const isOneline = (expected, received) =>
  typeof expected === 'string' &&
  typeof received === 'string' &&
  (!MULTILINE_REGEXP.test(expected) || !MULTILINE_REGEXP.test(received));

exports.isOneline = isOneline;
