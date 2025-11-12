'use strict'

const map = require('map-obj')
const { snakeCase } = require('snake-case')

const PlainObjectConstructor = {}.constructor

module.exports = function (obj, options) {
  if (Array.isArray(obj)) {
    if (obj.some(item => item.constructor !== PlainObjectConstructor)) {
      throw new Error('obj must be array of plain objects')
    }
  } else {
    if (obj.constructor !== PlainObjectConstructor) {
      throw new Error('obj must be an plain object')
    }
  }

  options = Object.assign({ deep: true, exclude: [], parsingOptions: {} }, options)

  return map(obj, function (key, val) {
    return [
      matches(options.exclude, key) ? key : snakeCase(key, options.parsingOptions),
      val,
      mapperOptions(key, val, options)
    ]
  }, options)
}

function matches (patterns, value) {
  return patterns.some(function (pattern) {
    return typeof pattern === 'string'
      ? pattern === value
      : pattern.test(value)
  })
}

function mapperOptions (key, val, options) {
  return options.shouldRecurse
    ? { shouldRecurse: options.shouldRecurse(key, val) }
    : undefined
}
