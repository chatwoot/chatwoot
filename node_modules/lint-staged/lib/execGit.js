'use strict'

const debug = require('debug')('lint-staged:git')
const execa = require('execa')

/**
 * Explicitly never recurse commands into submodules, overriding local/global configuration.
 * @see https://git-scm.com/docs/git-config#Documentation/git-config.txt-submodulerecurse
 */
const NO_SUBMODULE_RECURSE = ['-c', 'submodule.recurse=false']

const GIT_GLOBAL_OPTIONS = [...NO_SUBMODULE_RECURSE]

module.exports = async function execGit(cmd, options = {}) {
  debug('Running git command', cmd)
  try {
    const { stdout } = await execa('git', GIT_GLOBAL_OPTIONS.concat(cmd), {
      ...options,
      all: true,
      cwd: options.cwd || process.cwd(),
    })
    return stdout
  } catch ({ all }) {
    throw new Error(all)
  }
}

// exported for tests
module.exports.GIT_GLOBAL_OPTIONS = GIT_GLOBAL_OPTIONS
