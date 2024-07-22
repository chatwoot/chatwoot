/**
 * Creates a deep clone of the provided object.
 *
 * This function attempts to use the `structuredClone` method if available.
 * If `structuredClone` is not supported, it falls back to using
 * `JSON.parse(JSON.stringify())`.
 *
 * @param {*} obj - The object to be cloned. Can be of any type.
 * @returns {*} A deep clone of the input object.
 *
 * @throws {TypeError} If the object contains values that JSON cannot serialize
 *                     (e.g., functions, undefined) when falling back to
 *                     JSON methods.
 *
 * @example
 * const original = { a: 1, b: { c: 2 } };
 * const clone = cloneObject(original);
 * console.log(clone); // { a: 1, b: { c: 2 } }
 * console.log(original === clone); // false
 */
export function cloneObject(obj) {
  if (typeof structuredClone === 'function') {
    return structuredClone(obj);
  }

  // The JSON method doesn't handle all JavaScript types correctly and may cause unexpected behavior.
  // At the moment structuredClone has good adoption across browsers https://caniuse.com/mdn-api_structuredclone
  // and is the preferred method for cloning objects.
  //
  // We can consider implementing a more robust fallback method in the future if we find users are running into issues.
  // Ref: https://github.com/lukeed/klona
  return JSON.parse(JSON.stringify(obj));
}
