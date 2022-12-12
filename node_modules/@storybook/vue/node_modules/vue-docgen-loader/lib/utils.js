"use strict";

/**
 * Filter descriptors with given function.
 * @param {Object[] | {[name: string]: Object}} descriptors
 *   A list of descriptors.
 *   - vue-docgen-api < v4  ... descriptors is key-values
 *   - vue-docgen-api >= v4 ... descriptors is an array of objects
 * @param {(descriptor: Object) => boolean} filterFn
 *   Same as Array.prototype.filter but no index and self arguments.
 */
function filterDescriptors(descriptors, filterFn) {
  if (!descriptors) {
    // return falsy values as-is
    return descriptors;
  }

  if (descriptors instanceof Array) {
    return descriptors.filter(filterFn);
  }

  const entries = Object.entries(descriptors).filter(([, descriptor]) => filterFn(descriptor));
  return entries.reduce((obj, [key, value]) => ({ ...obj,
    [key]: value
  }), {});
}

exports.filterDescriptors = filterDescriptors;