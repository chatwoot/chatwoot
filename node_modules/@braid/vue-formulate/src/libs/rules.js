import isUrl from 'is-url'
import FileUpload from '../FileUpload'
import { equals, regexForFormat, isEmpty } from './utils'

/**
 * Library of rules
 */
export default {
  /**
   * Rule: the value must be "yes", "on", "1", or true
   */
  accepted: function ({ value }) {
    return Promise.resolve(['yes', 'on', '1', 1, true, 'true'].includes(value))
  },

  /**
   * Rule: checks if a value is after a given date. Defaults to current time
   */
  after: function ({ value }, compare = false) {
    const timestamp = Date.parse(compare || new Date())
    const fieldValue = Date.parse(value)
    return Promise.resolve(isNaN(fieldValue) ? false : (fieldValue > timestamp))
  },

  /**
   * Rule: checks if the value is only alpha
   */
  alpha: function ({ value }, set = 'default') {
    const sets = {
      default: /^[a-zA-ZÀ-ÖØ-öø-ÿĄąĆćĘęŁłŃńŚśŹźŻż]+$/,
      latin: /^[a-zA-Z]+$/
    }
    const selectedSet = sets.hasOwnProperty(set) ? set : 'default'
    return Promise.resolve(sets[selectedSet].test(value))
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ value }, set = 'default') {
    const sets = {
      default: /^[a-zA-Z0-9À-ÖØ-öø-ÿĄąĆćĘęŁłŃńŚśŹźŻż]+$/,
      latin: /^[a-zA-Z0-9]+$/
    }
    const selectedSet = sets.hasOwnProperty(set) ? set : 'default'
    return Promise.resolve(sets[selectedSet].test(value))
  },

  /**
   * Rule: checks if a value is after a given date. Defaults to current time
   */
  before: function ({ value }, compare = false) {
    const timestamp = Date.parse(compare || new Date())
    const fieldValue = Date.parse(value)
    return Promise.resolve(isNaN(fieldValue) ? false : (fieldValue < timestamp))
  },

  /**
   * Rule: checks if the value is between two other values
   */
  between: function ({ value }, from = 0, to = 10, force) {
    return Promise.resolve((() => {
      if (from === null || to === null || isNaN(from) || isNaN(to)) {
        return false
      }
      if ((!isNaN(value) && force !== 'length') || force === 'value') {
        value = Number(value)
        from = Number(from)
        to = Number(to)
        return (value > from && value < to)
      }
      if (typeof value === 'string' || force === 'length') {
        value = !isNaN(value) ? value.toString() : value
        return value.length > from && value.length < to
      }
      return false
    })())
  },

  /**
   * Confirm that the value of one field is the same as another, mostly used
   * for password confirmations.
   */
  confirm: function ({ value, getGroupValues, name }, field) {
    return Promise.resolve((() => {
      const values = getGroupValues()
      var confirmationFieldName = field
      if (!confirmationFieldName) {
        confirmationFieldName = /_confirm$/.test(name) ? name.substr(0, name.length - 8) : `${name}_confirm`
      }
      return values[confirmationFieldName] === value
    })())
  },

  /**
   * Rule: ensures the value is a date according to Date.parse(), or a format
   * regex.
   */
  date: function ({ value }, format = false) {
    return Promise.resolve((() => {
      if (format && typeof format === 'string') {
        return regexForFormat(format).test(value)
      }
      return !isNaN(Date.parse(value))
    })())
  },

  /**
   * Rule: tests
   */
  email: function ({ value }) {
    // eslint-disable-next-line
    const isEmail = /^(([^<>()\[\]\.,;:\s@\"]+(\.[^<>()\[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i
    return Promise.resolve(isEmail.test(value))
  },

  /**
   * Rule: Value ends with one of the given Strings
   */
  endsWith: function ({ value }, ...stack) {
    return Promise.resolve((() => {
      if (typeof value === 'string' && stack.length) {
        return stack.find(item => {
          return value.endsWith(item)
        }) !== undefined
      } else if (typeof value === 'string' && stack.length === 0) {
        return true
      }
      return false
    })())
  },

  /**
   * Rule: Value is in an array (stack).
   */
  in: function ({ value }, ...stack) {
    return Promise.resolve(stack.find(item => {
      if (typeof item === 'object') {
        return equals(item, value)
      }
      return item === value
    }) !== undefined)
  },

  /**
   * Rule: Match the value against a (stack) of patterns or strings
   */
  matches: function ({ value }, ...stack) {
    return Promise.resolve(!!stack.find(pattern => {
      if (typeof pattern === 'string' && pattern.substr(0, 1) === '/' && pattern.substr(-1) === '/') {
        pattern = new RegExp(pattern.substr(1, pattern.length - 2))
      }
      if (pattern instanceof RegExp) {
        return pattern.test(value)
      }
      return pattern === value
    }))
  },

  /**
   * Check the file type is correct.
   */
  mime: function ({ value }, ...types) {
    return Promise.resolve((() => {
      if (value instanceof FileUpload) {
        const fileList = value.getFiles()
        for (let i = 0; i < fileList.length; i++) {
          const file = fileList[i].file
          if (!types.includes(file.type)) {
            return false
          }
        }
      }
      return true
    })())
  },

  /**
   * Check the minimum value of a particular.
   */
  min: function ({ value }, minimum = 1, force) {
    return Promise.resolve((() => {
      if (Array.isArray(value)) {
        minimum = !isNaN(minimum) ? Number(minimum) : minimum
        return value.length >= minimum
      }
      if ((!isNaN(value) && force !== 'length') || force === 'value') {
        value = !isNaN(value) ? Number(value) : value
        return value >= minimum
      }
      if (typeof value === 'string' || (force === 'length')) {
        value = !isNaN(value) ? value.toString() : value
        return value.length >= minimum
      }
      return false
    })())
  },

  /**
   * Check the maximum value of a particular.
   */
  max: function ({ value }, maximum = 10, force) {
    return Promise.resolve((() => {
      if (Array.isArray(value)) {
        maximum = !isNaN(maximum) ? Number(maximum) : maximum
        return value.length <= maximum
      }
      if ((!isNaN(value) && force !== 'length') || force === 'value') {
        value = !isNaN(value) ? Number(value) : value
        return value <= maximum
      }
      if (typeof value === 'string' || (force === 'length')) {
        value = !isNaN(value) ? value.toString() : value
        return value.length <= maximum
      }
      return false
    })())
  },

  /**
   * Rule: Value is not in stack.
   */
  not: function ({ value }, ...stack) {
    return Promise.resolve(stack.find(item => {
      if (typeof item === 'object') {
        return equals(item, value)
      }
      return item === value
    }) === undefined)
  },

  /**
   * Rule: checks if the value is only alpha numeric
   */
  number: function ({ value }) {
    return Promise.resolve(!isNaN(value))
  },

  /**
   * Rule: must be a value - allows for an optional argument "whitespace" with a possible value 'trim' and default 'pre'.
   */
  required: function ({ value }, whitespace = 'pre') {
    return Promise.resolve((() => {
      if (Array.isArray(value)) {
        return !!value.length
      }
      if (value instanceof FileUpload) {
        return value.getFiles().length > 0
      }
      if (typeof value === 'string') {
        return whitespace === 'trim' ? !!value.trim() : !!value
      }
      if (typeof value === 'object') {
        return (!value) ? false : !!Object.keys(value).length
      }
      return true
    })())
  },

  /**
   * Rule: Value starts with one of the given Strings
   */
  startsWith: function ({ value }, ...stack) {
    return Promise.resolve((() => {
      if (typeof value === 'string' && stack.length) {
        return stack.find(item => {
          return value.startsWith(item)
        }) !== undefined
      } else if (typeof value === 'string' && stack.length === 0) {
        return true
      }
      return false
    })())
  },

  /**
   * Rule: checks if a string is a valid url
   */
  url: function ({ value }) {
    return Promise.resolve(isUrl(value))
  },

  /**
   * Rule: not a true rule — more like a compiler flag.
   */
  bail: function () {
    return Promise.resolve(true)
  },

  /**
   * Rule: not a true rule - more like a compiler flag.
   */
  optional: function ({ value }) {
    // So technically we "fail" this rule anytime the field is empty. This rule
    // is automatically hoisted to the top of the validation stack, and marked
    // as a "bail" rule, meaning if it fails, no further validation will be run.
    // Finally, the error message associated with this rule is filtered out.
    return Promise.resolve(!isEmpty(value))
  }
}
