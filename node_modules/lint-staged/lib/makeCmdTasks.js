'use strict'

const cliTruncate = require('cli-truncate')
const debug = require('debug')('lint-staged:make-cmd-tasks')

const resolveTaskFn = require('./resolveTaskFn')
const { createError } = require('./validateConfig')

const STDOUT_COLUMNS_DEFAULT = 80

const listrPrefixLength = {
  update: `    X `.length, // indented task title where X is a checkmark or a cross (failure)
  verbose: `[STARTED] `.length, // verbose renderer uses 7-letter STARTED/SUCCESS prefixes
}

/**
 * Get length of title based on the number of available columns prefix length
 * @param {string} renderer The name of the Listr renderer
 * @returns {number}
 */
const getTitleLength = (renderer, columns = process.stdout.columns) => {
  const prefixLength = listrPrefixLength[renderer] || 0
  return (columns || STDOUT_COLUMNS_DEFAULT) - prefixLength
}

/**
 * Creates and returns an array of listr tasks which map to the given commands.
 *
 * @param {object} options
 * @param {Array<string|Function>|string|Function} options.commands
 * @param {Array<string>} options.files
 * @param {string} options.gitDir
 * @param {string} options.renderer
 * @param {Boolean} shell
 * @param {Boolean} verbose
 */
const makeCmdTasks = async ({ commands, files, gitDir, renderer, shell, verbose }) => {
  debug('Creating listr tasks for commands %o', commands)
  const commandArray = Array.isArray(commands) ? commands : [commands]
  const cmdTasks = []

  for (const cmd of commandArray) {
    // command function may return array of commands that already include `stagedFiles`
    const isFn = typeof cmd === 'function'
    const resolved = isFn ? await cmd(files) : cmd

    const resolvedArray = Array.isArray(resolved) ? resolved : [resolved] // Wrap non-array command as array

    for (const command of resolvedArray) {
      // If the function linter didn't return string | string[]  it won't work
      // Do the validation here instead of `validateConfig` to skip evaluating the function multiple times
      if (isFn && typeof command !== 'string') {
        throw new Error(
          createError(
            '[Function]',
            'Function task should return a string or an array of strings',
            resolved
          )
        )
      }

      // Truncate title to single line based on renderer
      const title = cliTruncate(command, getTitleLength(renderer))
      const task = resolveTaskFn({ command, files, gitDir, isFn, shell, verbose })
      cmdTasks.push({ title, command, task })
    }
  }

  return cmdTasks
}

module.exports = makeCmdTasks
