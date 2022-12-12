'use strict'

const normalize = require('normalize-path')
const debugLog = require('debug')('lint-staged:resolveGitRepo')
const fs = require('fs')
const path = require('path')
const { promisify } = require('util')

const execGit = require('./execGit')
const { readFile } = require('./file')

const fsLstat = promisify(fs.lstat)

/**
 * Resolve path to the .git directory, with special handling for
 * submodules and worktrees
 */
const resolveGitConfigDir = async (gitDir) => {
  const defaultDir = normalize(path.join(gitDir, '.git'))
  const stats = await fsLstat(defaultDir)
  // If .git is a directory, use it
  if (stats.isDirectory()) return defaultDir
  // Otherwise .git is a file containing path to real location
  const file = (await readFile(defaultDir)).toString()
  return path.resolve(gitDir, file.replace(/^gitdir: /, '')).trim()
}

/**
 * Resolve git directory and possible submodule paths
 */
const resolveGitRepo = async (cwd) => {
  try {
    debugLog('Resolving git repo from `%s`', cwd)

    // Unset GIT_DIR before running any git operations in case it's pointing to an incorrect location
    debugLog('Unset GIT_DIR (was `%s`)', process.env.GIT_DIR)
    delete process.env.GIT_DIR
    debugLog('Unset GIT_WORK_TREE (was `%s`)', process.env.GIT_WORK_TREE)
    delete process.env.GIT_WORK_TREE

    const gitDir = normalize(await execGit(['rev-parse', '--show-toplevel'], { cwd }))
    const gitConfigDir = normalize(await resolveGitConfigDir(gitDir))

    debugLog('Resolved git directory to be `%s`', gitDir)
    debugLog('Resolved git config directory to be `%s`', gitConfigDir)

    return { gitDir, gitConfigDir }
  } catch (error) {
    debugLog('Failed to resolve git repo with error:', error)
    return { error, gitDir: null, gitConfigDir: null }
  }
}

module.exports = resolveGitRepo
