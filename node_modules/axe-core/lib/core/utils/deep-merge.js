/**
 * Deeply merge two objects into a new object without changing any of the source objects.
 * @see https://medium.com/javascript-in-plain-english/how-to-merge-objects-in-javascript-98f2209710e3
 * @param {...Object} sources
 * @return {Object}
 */
function deepMerge(...sources) {
  const target = {};

  sources.forEach(source => {
    if (!source || typeof source !== 'object' || Array.isArray(source)) {
      return;
    }

    for (const key of Object.keys(source)) {
      if (
        !target.hasOwnProperty(key) ||
        typeof source[key] !== 'object' ||
        Array.isArray(target[key])
      ) {
        target[key] = source[key];
      } else {
        target[key] = deepMerge(target[key], source[key]);
      }
    }
  });

  return target;
}

export default deepMerge;
