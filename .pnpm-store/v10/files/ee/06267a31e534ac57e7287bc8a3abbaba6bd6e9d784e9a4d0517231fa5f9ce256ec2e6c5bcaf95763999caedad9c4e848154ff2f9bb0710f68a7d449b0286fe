import debug from 'debug'
import { execa } from 'execa'

const debugLog = debug('lint-staged:execGit')

/**
 * Explicitly never recurse commands into submodules, overriding local/global configuration.
 * @see https://git-scm.com/docs/git-config#Documentation/git-config.txt-submodulerecurse
 */
const NO_SUBMODULE_RECURSE = ['-c', 'submodule.recurse=false']

// exported for tests
export const GIT_GLOBAL_OPTIONS = [...NO_SUBMODULE_RECURSE]

export const execGit = async (cmd, options = {}) => {
  debugLog('Running git command', cmd)
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
