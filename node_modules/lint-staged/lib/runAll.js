'use strict'

/** @typedef {import('./index').Logger} Logger */

const { Listr } = require('listr2')

const chunkFiles = require('./chunkFiles')
const debugLog = require('debug')('lint-staged:run')
const execGit = require('./execGit')
const generateTasks = require('./generateTasks')
const getRenderer = require('./getRenderer')
const getStagedFiles = require('./getStagedFiles')
const GitWorkflow = require('./gitWorkflow')
const makeCmdTasks = require('./makeCmdTasks')
const {
  DEPRECATED_GIT_ADD,
  FAILED_GET_STAGED_FILES,
  NOT_GIT_REPO,
  NO_STAGED_FILES,
  NO_TASKS,
  SKIPPED_GIT_ERROR,
  skippingBackup,
} = require('./messages')
const resolveGitRepo = require('./resolveGitRepo')
const {
  applyModificationsSkipped,
  cleanupEnabled,
  cleanupSkipped,
  getInitialState,
  hasPartiallyStagedFiles,
  restoreOriginalStateEnabled,
  restoreOriginalStateSkipped,
  restoreUnstagedChangesSkipped,
} = require('./state')
const { GitRepoError, GetStagedFilesError, GitError } = require('./symbols')

const createError = (ctx) => Object.assign(new Error('lint-staged failed'), { ctx })

/**
 * Executes all tasks and either resolves or rejects the promise
 *
 * @param {object} options
 * @param {Object} [options.allowEmpty] - Allow empty commits when tasks revert all staged changes
 * @param {boolean | number} [options.concurrent] - The number of tasks to run concurrently, or false to run tasks serially
 * @param {Object} [options.config] - Task configuration
 * @param {Object} [options.cwd] - Current working directory
 * @param {boolean} [options.debug] - Enable debug mode
 * @param {number} [options.maxArgLength] - Maximum argument string length
 * @param {boolean} [options.quiet] - Disable lint-staged’s own console output
 * @param {boolean} [options.relative] - Pass relative filepaths to tasks
 * @param {boolean} [options.shell] - Skip parsing of tasks for better shell support
 * @param {boolean} [options.stash] - Enable the backup stash, and revert in case of errors
 * @param {boolean} [options.verbose] - Show task output even when tasks succeed; by default only failed output is shown
 * @param {Logger} logger
 * @returns {Promise}
 */
const runAll = async (
  {
    allowEmpty = false,
    concurrent = true,
    config,
    cwd = process.cwd(),
    debug = false,
    maxArgLength,
    quiet = false,
    relative = false,
    shell = false,
    stash = true,
    verbose = false,
  },
  logger = console
) => {
  debugLog('Running all linter scripts')

  const ctx = getInitialState({ quiet })

  const { gitDir, gitConfigDir } = await resolveGitRepo(cwd)
  if (!gitDir) {
    if (!quiet) ctx.output.push(NOT_GIT_REPO)
    ctx.errors.add(GitRepoError)
    throw createError(ctx)
  }

  // Test whether we have any commits or not.
  // Stashing must be disabled with no initial commit.
  const hasInitialCommit = await execGit(['log', '-1'], { cwd: gitDir })
    .then(() => true)
    .catch(() => false)

  // Lint-staged should create a backup stash only when there's an initial commit
  ctx.shouldBackup = hasInitialCommit && stash
  if (!ctx.shouldBackup) {
    logger.warn(skippingBackup(hasInitialCommit))
  }

  const files = await getStagedFiles({ cwd: gitDir })
  if (!files) {
    if (!quiet) ctx.output.push(FAILED_GET_STAGED_FILES)
    ctx.errors.add(GetStagedFilesError)
    throw createError(ctx, GetStagedFilesError)
  }
  debugLog('Loaded list of staged files in git:\n%O', files)

  // If there are no files avoid executing any lint-staged logic
  if (files.length === 0) {
    if (!quiet) ctx.output.push(NO_STAGED_FILES)
    return ctx
  }

  const stagedFileChunks = chunkFiles({ baseDir: gitDir, files, maxArgLength, relative })
  const chunkCount = stagedFileChunks.length
  if (chunkCount > 1) debugLog(`Chunked staged files into ${chunkCount} part`, chunkCount)

  // lint-staged 10 will automatically add modifications to index
  // Warn user when their command includes `git add`
  let hasDeprecatedGitAdd = false

  const listrOptions = {
    ctx,
    exitOnError: false,
    nonTTYRenderer: 'verbose',
    registerSignalListeners: false,
    ...getRenderer({ debug, quiet }),
  }

  const listrTasks = []

  // Set of all staged files that matched a task glob. Values in a set are unique.
  const matchedFiles = new Set()

  for (const [index, files] of stagedFileChunks.entries()) {
    const chunkTasks = generateTasks({ config, cwd, gitDir, files, relative })
    const chunkListrTasks = []

    for (const task of chunkTasks) {
      const subTasks = await makeCmdTasks({
        commands: task.commands,
        files: task.fileList,
        gitDir,
        renderer: listrOptions.renderer,
        shell,
        verbose,
      })

      // Add files from task to match set
      task.fileList.forEach((file) => {
        matchedFiles.add(file)
      })

      hasDeprecatedGitAdd = subTasks.some((subTask) => subTask.command === 'git add')

      chunkListrTasks.push({
        title: `Running tasks for ${task.pattern}`,
        task: async () =>
          new Listr(subTasks, {
            // In sub-tasks we don't want to run concurrently
            // and we want to abort on errors
            ...listrOptions,
            concurrent: false,
            exitOnError: true,
          }),
        skip: () => {
          // Skip task when no files matched
          if (task.fileList.length === 0) {
            return `No staged files match ${task.pattern}`
          }
          return false
        },
      })
    }

    listrTasks.push({
      // No need to show number of task chunks when there's only one
      title:
        chunkCount > 1 ? `Running tasks (chunk ${index + 1}/${chunkCount})...` : 'Running tasks...',
      task: () => new Listr(chunkListrTasks, { ...listrOptions, concurrent }),
      skip: () => {
        // Skip if the first step (backup) failed
        if (ctx.errors.has(GitError)) return SKIPPED_GIT_ERROR
        // Skip chunk when no every task is skipped (due to no matches)
        if (chunkListrTasks.every((task) => task.skip())) return 'No tasks to run.'
        return false
      },
    })
  }

  if (hasDeprecatedGitAdd) {
    logger.warn(DEPRECATED_GIT_ADD)
  }

  // If all of the configured tasks should be skipped
  // avoid executing any lint-staged logic
  if (listrTasks.every((task) => task.skip())) {
    if (!quiet) ctx.output.push(NO_TASKS)
    return ctx
  }

  // Chunk matched files for better Windows compatibility
  const matchedFileChunks = chunkFiles({
    // matched files are relative to `cwd`, not `gitDir`, when `relative` is used
    baseDir: cwd,
    files: Array.from(matchedFiles),
    maxArgLength,
    relative: false,
  })

  const git = new GitWorkflow({ allowEmpty, gitConfigDir, gitDir, matchedFileChunks })

  const runner = new Listr(
    [
      {
        title: 'Preparing...',
        task: (ctx) => git.prepare(ctx),
      },
      {
        title: 'Hiding unstaged changes to partially staged files...',
        task: (ctx) => git.hideUnstagedChanges(ctx),
        enabled: hasPartiallyStagedFiles,
      },
      ...listrTasks,
      {
        title: 'Applying modifications...',
        task: (ctx) => git.applyModifications(ctx),
        skip: applyModificationsSkipped,
      },
      {
        title: 'Restoring unstaged changes to partially staged files...',
        task: (ctx) => git.restoreUnstagedChanges(ctx),
        enabled: hasPartiallyStagedFiles,
        skip: restoreUnstagedChangesSkipped,
      },
      {
        title: 'Reverting to original state because of errors...',
        task: (ctx) => git.restoreOriginalState(ctx),
        enabled: restoreOriginalStateEnabled,
        skip: restoreOriginalStateSkipped,
      },
      {
        title: 'Cleaning up...',
        task: (ctx) => git.cleanup(ctx),
        enabled: cleanupEnabled,
        skip: cleanupSkipped,
      },
    ],
    listrOptions
  )

  await runner.run()

  if (ctx.errors.size > 0) {
    throw createError(ctx)
  }

  return ctx
}

module.exports = runAll
