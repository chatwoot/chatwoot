'use strict'

const micromatch = require('micromatch')
const normalize = require('normalize-path')
const path = require('path')

const debug = require('debug')('lint-staged:gen-tasks')

/**
 * Generates all task commands, and filelist
 *
 * @param {object} options
 * @param {Object} [options.config] - Task configuration
 * @param {Object} [options.cwd] - Current working directory
 * @param {boolean} [options.gitDir] - Git root directory
 * @param {boolean} [options.files] - Staged filepaths
 * @param {boolean} [options.relative] - Whether filepaths to should be relative to gitDir
 */
module.exports = function generateTasks({
  config,
  cwd = process.cwd(),
  gitDir,
  files,
  relative = false,
}) {
  debug('Generating linter tasks')

  const absoluteFiles = files.map((file) => normalize(path.resolve(gitDir, file)))
  const relativeFiles = absoluteFiles.map((file) => normalize(path.relative(cwd, file)))

  return Object.entries(config).map(([pattern, commands]) => {
    const isParentDirPattern = pattern.startsWith('../')

    const fileList = micromatch(
      relativeFiles
        // Only worry about children of the CWD unless the pattern explicitly
        // specifies that it concerns a parent directory.
        .filter((file) => {
          if (isParentDirPattern) return true
          return !file.startsWith('..') && !path.isAbsolute(file)
        }),
      pattern,
      {
        cwd,
        dot: true,
        // If pattern doesn't look like a path, enable `matchBase` to
        // match against filenames in every directory. This makes `*.js`
        // match both `test.js` and `subdirectory/test.js`.
        matchBase: !pattern.includes('/'),
      }
    ).map((file) => normalize(relative ? file : path.resolve(cwd, file)))

    const task = { pattern, commands, fileList }
    debug('Generated task: \n%O', task)

    return task
  })
}
