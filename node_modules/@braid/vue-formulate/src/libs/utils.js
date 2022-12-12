import nanoid from 'nanoid/non-secure'
import FileUpload from '../FileUpload'

/**
 * Function to map over an object.
 * @param {Object} obj An object to map over
 * @param {Function} callback
 */
export function map (original, callback) {
  const obj = {}
  for (let key in original) {
    obj[key] = callback(key, original[key])
  }
  return obj
}

/**
 * Shallow equal.
 * @param {} objA
 * @param {*} objB
 */
export function equals (objA, objB, deep = false) {
  if (objA === objB) {
    return true
  }
  if (!objA || !objB) {
    return false
  }
  if (typeof objA !== 'object' && typeof objB !== 'object') {
    // Compare scalar values
    return objA === objB
  }
  var aKeys = Object.keys(objA)
  var bKeys = Object.keys(objB)
  var len = aKeys.length

  if (bKeys.length !== len) {
    return false
  }

  for (var i = 0; i < len; i++) {
    var key = aKeys[i]
    if ((!deep && objA[key] !== objB[key]) || (deep && !equals(objA[key], objB[key], deep))) {
      return false
    }
  }
  return true
}

/**
 * Given a string, convert snake_case to camelCase
 * @param {String} string
 */
export function camel (string) {
  if (typeof string === 'string') {
    return string.replace(/([_-][a-z0-9])/ig, ($1) => {
      if (string.indexOf($1) !== 0 && !/[_-]/.test(string[string.indexOf($1) - 1])) {
        return $1.toUpperCase().replace(/[_-]/, '')
      }
      return $1
    })
  }
  return string
}

export function kebabToCamel (string) {

}

/**
 * Given a string, capitalize it. happyDay => HappyDay
 * @param {string} str
 */
export function cap (str) {
  return typeof str === 'string' ? str[0].toUpperCase() + str.substr(1) : str
}

/**
 * Given a string, object, falsey, or array - return an array.
 * @param {mixed} item
 */
export function arrayify (item) {
  if (!item) {
    return []
  }
  if (typeof item === 'string') {
    return [item]
  }
  if (Array.isArray(item)) {
    return item
  }
  if (typeof item === 'object') {
    return Object.values(item)
  }
  return []
}

/**
 * Given an array or string return an array of callables.
 * @param {array|string} validation
 * @param {array} rules and array of functions
 * @return {array} an array of functions
 */
export function parseRules (validation, rules) {
  if (typeof validation === 'string') {
    return parseRules(validation.split('|'), rules)
  }
  if (!Array.isArray(validation)) {
    return []
  }
  return validation.map(rule => parseRule(rule, rules)).filter(f => !!f)
}

/**
 * Given a string or function, parse it and return an array in the format
 * [fn, [...arguments]]
 * @param {string|function} rule
 */
function parseRule (rule, rules) {
  if (typeof rule === 'function') {
    return [rule, []]
  }
  if (Array.isArray(rule) && rule.length) {
    rule = rule.map(r => r) // light clone
    const [ruleName, modifier] = parseModifier(rule.shift())
    if (typeof ruleName === 'string' && rules.hasOwnProperty(ruleName)) {
      return [rules[ruleName], rule, ruleName, modifier]
    }
    if (typeof ruleName === 'function') {
      return [ruleName, rule, ruleName, modifier]
    }
  }
  if (typeof rule === 'string' && rule) {
    const segments = rule.split(':')
    const [ruleName, modifier] = parseModifier(segments.shift())
    if (rules.hasOwnProperty(ruleName)) {
      return [rules[ruleName], segments.length ? segments.join(':').split(',') : [], ruleName, modifier]
    } else {
      throw new Error(`Unknown validation rule ${rule}`)
    }
  }
  return false
}

/**
 * Return the rule name with the applicable modifier as an array.
 * @param {string} ruleName
 * @return {array} [ruleName, modifier]
 */
function parseModifier (ruleName) {
  if (/^[\^]/.test(ruleName.charAt(0))) {
    return [camel(ruleName.substr(1)), ruleName.charAt(0)]
  }
  return [camel(ruleName), null]
}

/**
 * Given an array of rules, group them by bail signals. For example for this:
 * bail|required|min:10|max:20
 * we would expect:
 * [[required], [min], [max]]
 * because any sub-array failure would cause a shutdown. While
 * ^required|min:10|max:10
 * would return:
 * [[required], [min, max]]
 * and no bailing would produce:
 * [[required, min, max]]
 * @param {array} rules
 */
export function groupBails (rules) {
  const groups = []
  const bailIndex = rules.findIndex(([,, rule]) => rule.toLowerCase() === 'bail')
  const optionalIndex = rules.findIndex(([,, rule]) => rule.toLowerCase() === 'optional')
  if (optionalIndex >= 0) {
    const rule = rules.splice(optionalIndex, 1)
    groups.push(Object.defineProperty(rule, 'bail', { value: true }))
  }
  if (bailIndex >= 0) {
    // Get all the rules until the first bail rule (dont include the bail)
    const preBail = rules.splice(0, bailIndex + 1).slice(0, -1)
    // Rules before the `bail` rule are non-bailing
    preBail.length && groups.push(preBail)
    // All remaining rules are bailing rule groups
    rules.map(rule => groups.push(Object.defineProperty([rule], 'bail', { value: true })))
  } else {
    groups.push(rules)
  }

  return groups.reduce((groups, group) => {
    // Recursively split rules into groups based on the modifiers.
    const splitByMod = (group, bailGroup = false) => {
      if (group.length < 2) {
        return Object.defineProperty([group], 'bail', { value: bailGroup })
      }
      const splits = []
      const modIndex = group.findIndex(([,,, modifier]) => modifier === '^')
      if (modIndex >= 0) {
        const preMod = group.splice(0, modIndex)
        // rules before the modifier are non-bailing rules.
        preMod.length && splits.push(...splitByMod(preMod, bailGroup))
        splits.push(Object.defineProperty([group.shift()], 'bail', { value: true }))
        // rules after the modifier are non-bailing rules.
        group.length && splits.push(...splitByMod(group, bailGroup))
      } else {
        splits.push(group)
      }
      return splits
    }
    return groups.concat(splitByMod(group))
  }, [])
}

/**
 * Escape a string for use in regular expressions.
 * @param {string} string
 */
export function escapeRegExp (string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') // $& means the whole matched string
}

/**
 * Given a string format (date) return a regex to match against.
 * @param {string} format
 */
export function regexForFormat (format) {
  let escaped = `^${escapeRegExp(format)}$`
  const formats = {
    MM: '(0[1-9]|1[012])',
    M: '([1-9]|1[012])',
    DD: '([012][0-9]|3[01])',
    D: '([012]?[0-9]|3[01])',
    YYYY: '\\d{4}',
    YY: '\\d{2}'
  }
  return new RegExp(Object.keys(formats).reduce((regex, format) => {
    return regex.replace(format, formats[format])
  }, escaped))
}

/**
 * Check if
 * @param {mixed} data
 */
export function isValueType (data) {
  switch (typeof data) {
    case 'symbol':
    case 'number':
    case 'string':
    case 'boolean':
    case 'undefined':
      return true
    default:
      if (data === null) {
        return true
      }
      return false
  }
}

/**
 * A simple (somewhat non-comprehensive) cloneDeep function, valid for our use
 * case of needing to unbind reactive watchers.
 */
export function cloneDeep (obj) {
  if (typeof obj !== 'object') {
    return obj
  }
  const isArr = Array.isArray(obj)
  const newObj = isArr ? [] : {}
  for (const key in obj) {
    if (obj[key] instanceof FileUpload || isValueType(obj[key])) {
      newObj[key] = obj[key]
    } else {
      newObj[key] = cloneDeep(obj[key])
    }
  }
  return newObj
}

/**
 * Given a locale string, parse the options.
 * @param {string} locale
 */
export function parseLocale (locale) {
  const segments = locale.split('-')
  return segments.reduce((options, segment) => {
    if (options.length) {
      options.unshift(`${options[0]}-${segment}`)
    }
    return options.length ? options : [segment]
  }, [])
}

/**
 * Shorthand for Object.prototype.hasOwnProperty.call (space saving)
 */
export function has (ctx, prop) {
  return Object.prototype.hasOwnProperty.call(ctx, prop)
}

/**
 * Set a unique Symbol identifier on an object.
 * @param {object} o
 * @param {Symbol} id
 */
export function setId (o, id) {
  if (!has(o, '__id') || id) {
    return Object.defineProperty(o, '__id', Object.assign(Object.create(null), { value: id || nanoid(9) }))
  }
  return o
}

/**
 * Determines if a given value is considered "empty"
 * @param {any} value
 */
export function isEmpty (value) {
  if (typeof value === 'number') {
    return false
  }
  return (
    value === undefined ||
    value === '' ||
    value === null ||
    value === false ||
    (
      Array.isArray(value) && !value.some(v => !isEmpty(v))
    ) ||
    (
      (value && !Array.isArray(value) && typeof value === 'object' && isEmpty(Object.values(value)))
    )
  )
}

/**
 * Extract a set of attributes.
 * @param {object} obj object to extract from
 * @param {array} array of keys to extract
 */
export function extractAttributes (obj, keys) {
  return Object.keys(obj).reduce((props, key) => {
    const propKey = camel(key)
    if (keys.includes(propKey)) {
      props[propKey] = obj[key]
    }
    return props
  }, {})
}

/**
 * Create a hash of a given string.
 * Credit: https://stackoverflow.com/questions/7616461/generate-a-hash-from-string-in-javascript#answer-52171480
 *
 * @param {string} str
 * @param {int} seed
 */
export function cyrb43 (str, seed = 0) {
  let h1 = 0xdeadbeef ^ seed
  let h2 = 0x41c6ce57 ^ seed
  for (let i = 0, ch; i < str.length; i++) {
    ch = str.charCodeAt(i)
    h1 = Math.imul(h1 ^ ch, 2654435761)
    h2 = Math.imul(h2 ^ ch, 1597334677)
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909)
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909)
  return 4294967296 * (2097151 & h2) + (h1 >>> 0)
};

/**
 * Create a new debouncer — will debounce any function calls.
 */
export function createDebouncer () {
  let timeout
  return function debounceFn (fn, args, delay) {
    if (timeout) {
      clearTimeout(timeout)
    }
    timeout = setTimeout(() => fn.call(this, ...args), delay)
  }
}
