import "core-js/modules/es.array.reduce.js";
// Utilities for handling parameters
import isPlainObject from 'lodash/isPlainObject';
/**
 * Safely combine parameters recursively. Only copy objects when needed.
 * Algorithm = always overwrite the existing value UNLESS both values
 * are plain objects. In this case flag the key as "special" and handle
 * it with a heuristic.
 */

export const combineParameters = (...parameterSets) => {
  const mergeKeys = {};
  const combined = parameterSets.filter(Boolean).reduce((acc, p) => {
    Object.entries(p).forEach(([key, value]) => {
      const existing = acc[key];

      if (Array.isArray(value) || typeof existing === 'undefined') {
        acc[key] = value;
      } else if (isPlainObject(value) && isPlainObject(existing)) {
        // do nothing, we'll handle this later
        mergeKeys[key] = true;
      } else if (typeof value !== 'undefined') {
        acc[key] = value;
      }
    });
    return acc;
  }, {});
  Object.keys(mergeKeys).forEach(key => {
    const mergeValues = parameterSets.filter(Boolean).map(p => p[key]).filter(value => typeof value !== 'undefined');

    if (mergeValues.every(value => isPlainObject(value))) {
      combined[key] = combineParameters(...mergeValues);
    } else {
      combined[key] = mergeValues[mergeValues.length - 1];
    }
  });
  return combined;
};