/* @flow */

/**
 * constants
 */

export const numberFormatKeys = [
  'compactDisplay',
  'currency',
  'currencyDisplay',
  'currencySign',
  'localeMatcher',
  'notation',
  'numberingSystem',
  'signDisplay',
  'style',
  'unit',
  'unitDisplay',
  'useGrouping',
  'minimumIntegerDigits',
  'minimumFractionDigits',
  'maximumFractionDigits',
  'minimumSignificantDigits',
  'maximumSignificantDigits'
]

/**
 * utilities
 */

export function warn (msg: string, err: ?Error): void {
  if (typeof console !== 'undefined') {
    console.warn('[vue-i18n] ' + msg)
    /* istanbul ignore if */
    if (err) {
      console.warn(err.stack)
    }
  }
}

export function error (msg: string, err: ?Error): void {
  if (typeof console !== 'undefined') {
    console.error('[vue-i18n] ' + msg)
    /* istanbul ignore if */
    if (err) {
      console.error(err.stack)
    }
  }
}

export const isArray = Array.isArray

export function isObject (obj: mixed): boolean %checks {
  return obj !== null && typeof obj === 'object'
}

export function isBoolean (val: mixed): boolean %checks {
  return typeof val === 'boolean'
}

export function isString (val: mixed): boolean %checks {
  return typeof val === 'string'
}

const toString: Function = Object.prototype.toString
const OBJECT_STRING: string = '[object Object]'
export function isPlainObject (obj: any): boolean {
  return toString.call(obj) === OBJECT_STRING
}

export function isNull (val: mixed): boolean {
  return val === null || val === undefined
}

export function isFunction (val: mixed): boolean %checks {
  return typeof val === 'function'
}

export function parseArgs (...args: Array<mixed>): Object {
  let locale: ?string = null
  let params: mixed = null
  if (args.length === 1) {
    if (isObject(args[0]) || isArray(args[0])) {
      params = args[0]
    } else if (typeof args[0] === 'string') {
      locale = args[0]
    }
  } else if (args.length === 2) {
    if (typeof args[0] === 'string') {
      locale = args[0]
    }
    /* istanbul ignore if */
    if (isObject(args[1]) || isArray(args[1])) {
      params = args[1]
    }
  }

  return { locale, params }
}

export function looseClone (obj: Object): Object {
  return JSON.parse(JSON.stringify(obj))
}

export function remove (arr: Set<any>, item: any): Set<any> | void {
  if (arr.delete(item)) {
    return arr
  }
}

export function includes (arr: Array<any>, item: any): boolean {
  return !!~arr.indexOf(item)
}

const hasOwnProperty = Object.prototype.hasOwnProperty
export function hasOwn (obj: Object | Array<*>, key: string): boolean {
  return hasOwnProperty.call(obj, key)
}

export function merge (target: Object): Object {
  const output = Object(target)
  for (let i = 1; i < arguments.length; i++) {
    const source = arguments[i]
    if (source !== undefined && source !== null) {
      let key
      for (key in source) {
        if (hasOwn(source, key)) {
          if (isObject(source[key])) {
            output[key] = merge(output[key], source[key])
          } else {
            output[key] = source[key]
          }
        }
      }
    }
  }
  return output
}

export function looseEqual (a: any, b: any): boolean {
  if (a === b) { return true }
  const isObjectA: boolean = isObject(a)
  const isObjectB: boolean = isObject(b)
  if (isObjectA && isObjectB) {
    try {
      const isArrayA: boolean = isArray(a)
      const isArrayB: boolean = isArray(b)
      if (isArrayA && isArrayB) {
        return a.length === b.length && a.every((e: any, i: number): boolean => {
          return looseEqual(e, b[i])
        })
      } else if (!isArrayA && !isArrayB) {
        const keysA: Array<string> = Object.keys(a)
        const keysB: Array<string> = Object.keys(b)
        return keysA.length === keysB.length && keysA.every((key: string): boolean => {
          return looseEqual(a[key], b[key])
        })
      } else {
        /* istanbul ignore next */
        return false
      }
    } catch (e) {
      /* istanbul ignore next */
      return false
    }
  } else if (!isObjectA && !isObjectB) {
    return String(a) === String(b)
  } else {
    return false
  }
}

/**
 * Sanitizes html special characters from input strings. For mitigating risk of XSS attacks.
 * @param rawText The raw input from the user that should be escaped.
 */
function escapeHtml(rawText: string): string {
  return rawText
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

/**
 * Escapes html tags and special symbols from all provided params which were returned from parseArgs().params.
 * This method performs an in-place operation on the params object.
 *
 * @param {any} params Parameters as provided from `parseArgs().params`.
 *                     May be either an array of strings or a string->any map.
 *
 * @returns The manipulated `params` object.
 */
export function escapeParams(params: any): any {
  if(params != null) {
    Object.keys(params).forEach(key => {
      if(typeof(params[key]) == 'string') {
        params[key] = escapeHtml(params[key])
      }
    })
  }
  return params
}
