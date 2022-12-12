/* eslint no-prototype-builtins: 0 */

'use strict'

const chalk = require('chalk')
const format = require('stringify-object')

const debug = require('debug')('lint-staged:cfg')

const TEST_DEPRECATED_KEYS = new Map([
  ['concurrent', (key) => typeof key === 'boolean'],
  ['chunkSize', (key) => typeof key === 'number'],
  ['globOptions', (key) => typeof key === 'object'],
  ['linters', (key) => typeof key === 'object'],
  ['ignore', (key) => Array.isArray(key)],
  ['subTaskConcurrency', (key) => typeof key === 'number'],
  ['renderer', (key) => typeof key === 'string'],
  ['relative', (key) => typeof key === 'boolean'],
])

const formatError = (helpMsg) => `● Validation Error:

  ${helpMsg}

Please refer to https://github.com/okonet/lint-staged#configuration for more information...`

const createError = (opt, helpMsg, value) =>
  formatError(`Invalid value for '${chalk.bold(opt)}'.

  ${helpMsg}.
 
  Configured value is: ${chalk.bold(
    format(value, { inlineCharacterLimit: Number.POSITIVE_INFINITY })
  )}`)

/**
 * Runs config validation. Throws error if the config is not valid.
 * @param config {Object}
 * @returns config {Object}
 */
module.exports = function validateConfig(config) {
  debug('Validating config')

  const errors = []

  if (!config || typeof config !== 'object') {
    errors.push('Configuration should be an object!')
  } else {
    const entries = Object.entries(config)

    if (entries.length === 0) {
      errors.push('Configuration should not be empty!')
    }

    entries.forEach(([pattern, task]) => {
      if (TEST_DEPRECATED_KEYS.has(pattern)) {
        const testFn = TEST_DEPRECATED_KEYS.get(pattern)
        if (testFn(task)) {
          errors.push(
            createError(
              pattern,
              'Advanced configuration has been deprecated. For more info, please visit: https://github.com/okonet/lint-staged',
              task
            )
          )
        }
      }

      if (
        (!Array.isArray(task) ||
          task.some((item) => typeof item !== 'string' && typeof item !== 'function')) &&
        typeof task !== 'string' &&
        typeof task !== 'function'
      ) {
        errors.push(
          createError(
            pattern,
            'Should be a string, a function, or an array of strings and functions',
            task
          )
        )
      }
    })
  }

  if (errors.length) {
    throw new Error(errors.join('\n'))
  }

  return config
}

module.exports.createError = createError
