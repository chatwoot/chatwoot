import debug from 'debug'

import { configurationError } from './messages.js'
import { resolveTaskFn } from './resolveTaskFn.js'

const debugLog = debug('lint-staged:makeCmdTasks')

/**
 * Creates and returns an array of listr tasks which map to the given commands.
 *
 * @param {object} options
 * @param {Array<string|Function>|string|Function} options.commands
 * @param {string} options.cwd
 * @param {Array<string>} options.files
 * @param {string} options.gitDir
 * @param {Boolean} shell
 * @param {Boolean} verbose
 */
export const makeCmdTasks = async ({ commands, cwd, files, gitDir, shell, verbose }) => {
  debugLog('Creating listr tasks for commands %o', commands)
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
          configurationError(
            '[Function]',
            'Function task should return a string or an array of strings',
            resolved
          )
        )
      }

      const task = resolveTaskFn({ command, cwd, files, gitDir, isFn, shell, verbose })
      cmdTasks.push({ title: command, command, task })
    }
  }

  return cmdTasks
}
