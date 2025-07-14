// Code derived from https://github.com/jonschlinkert/is-plain-object/blob/master/is-plain-object.js

function isObject(o: unknown): o is Object {
  return Object.prototype.toString.call(o) === '[object Object]'
}

export function isPlainObject(o: unknown): o is Record<PropertyKey, unknown> {
  if (isObject(o) === false) return false

  // If has modified constructor
  const ctor = (o as any).constructor
  if (ctor === undefined) return true

  // If has modified prototype
  const prot = ctor.prototype
  if (isObject(prot) === false) return false

  // If constructor does not have an Object-specific method
  // eslint-disable-next-line no-prototype-builtins
  if ((prot as Object).hasOwnProperty('isPrototypeOf') === false) {
    return false
  }

  // Most likely a plain Object
  return true
}
