const { stringify } = require('flatted')

const isObject = (value) => typeof value === 'object'
  && value !== null
  && (value.length === undefined || value.length === null)

const isNotObject = (value) => !isObject(value)

const isBoolean = (str) => /^true/.test(str) || /^false/.test(str)

const isEmpty = (value) => value === null || value === undefined

const isString = (key) => key && typeof key === 'string'

const isStrPath = (key) => {
  if (!isString(key)) throw new Error(`Key ${key} should be string`)
  return isString(key) && key.includes('.')
}

const isArray = (value) => Array.isArray(value)

const isEqual = (target, source) => stringify(target) === stringify(source)

const canMerge = (value) => isObject(value) || isArray(value)

const prettyPrint = (obj) => JSON.stringify(obj, null, 2)

const chdirTestApp = () => {
  try {
    return process.chdir('test/test_app')
  } catch (e) {
    return null
  }
}

const chdirCwd = () => process.chdir(process.cwd())

const resetEnv = () => {
  process.env = {}
}

const ensureTrailingSlash = (path) => (path.endsWith('/') ? path : `${path}/`)

module.exports = {
  chdirTestApp,
  chdirCwd,
  ensureTrailingSlash,
  isObject,
  isNotObject,
  isBoolean,
  isArray,
  isEqual,
  isEmpty,
  isStrPath,
  canMerge,
  prettyPrint,
  resetEnv
}
