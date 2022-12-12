const assert = require('assert')

const invalidChars = /[^a-zA-Z0-9:]+/g

/**
 * Convert text to kebab-case
 * @param {string} str Text to be converted
 * @return {string}
 */
function kebabCase (str) {
  return str
    .replace(/[A-Z]/g, match => '-' + match)
    .replace(/([^a-zA-Z])-([A-Z])/g, match => match[0] + match[2])
    .replace(/^-/, '')
    .replace(invalidChars, '-')
    .toLowerCase()
}

/**
 * Convert text to snake_case
 * @param {string} str Text to be converted
 * @return {string}
 */
function snakeCase (str) {
  return str
    .replace(/[A-Z]/g, match => '_' + match)
    .replace(/([^a-zA-Z])_([A-Z])/g, match => match[0] + match[2])
    .replace(/^_/, '')
    .replace(invalidChars, '_')
    .toLowerCase()
}

/**
 * Convert text to camelCase
 * @param {string} str Text to be converted
 * @return {string} Converted string
 */
function camelCase (str) {
  return str
    .replace(/_/g, (_, index) => index === 0 ? _ : '-')
    .replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) =>
      index === 0 ? letter.toLowerCase() : letter.toUpperCase()
    )
    .replace(invalidChars, '')
}

/**
 * Convert text to PascalCase
 * @param {string} str Text to be converted
 * @return {string} Converted string
 */
function pascalCase (str) {
  return str
    .replace(/_/g, (_, index) => index === 0 ? _ : '-')
    .replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) => letter.toUpperCase())
    .replace(invalidChars, '')
}

const convertersMap = {
  'kebab-case': kebabCase,
  'snake_case': snakeCase,
  'camelCase': camelCase,
  'PascalCase': pascalCase
}

module.exports = {
  allowedCaseOptions: [
    'camelCase',
    'kebab-case',
    'PascalCase'
  ],

  /**
   * Return case converter
   * @param {string} name type of converter to return ('camelCase', 'kebab-case', 'PascalCase')
   * @return {kebabCase|camelCase|pascalCase}
   */
  getConverter (name) {
    assert(typeof name === 'string')

    return convertersMap[name] || pascalCase
  },

  camelCase,
  pascalCase,
  kebabCase,
  snakeCase
}
