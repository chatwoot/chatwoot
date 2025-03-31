/** @typedef {import('./index').Logger} Logger */

import path from 'node:path'

import chalk from 'chalk'
import debug from 'debug'
import { Listr } from 'listr2'

import { chunkFiles } from './chunkFiles.js'
import { execGit } from './execGit.js'
import { generateTasks } from './generateTasks.js'
import { getRenderer } from './getRenderer.js'
import { getStagedFiles } from './getStagedFiles.js'
import { GitWorkflow } from './gitWorkflow.js'
import { groupFilesByConfig } from './groupFilesByConfig.js'
import { makeCmdTasks } from './makeCmdTasks.js'
import {
  DEPRECATED_GIT_ADD,
  FAILED_GET_STAGED_FILES,
  NOT_GIT_REPO,
  NO_STAGED_FILES,
  NO_TASKS,
  SKIPPED_GIT_ERROR,
  skippingBackup,
} from './messages.js'
import { normalizePath } from './normalizePath.js'
import { resolveGitRepo } from './resolveGitRepo.js'
import {
  applyModificationsSkipped,
  cleanupEnabled,
  cleanupSkipped,
  getInitialState,
  hasPartiallyStagedFiles,
  restoreOriginalStateEnabled,
  restoreOriginalStateSkipped,
  restoreUnstagedChangesSkipped,
} from './state.js'
import { GitRepoError, GetStagedFilesError, GitError, ConfigNotFoundError } from './symbols.js'
import { searchConfigs } from './searchConfigs.js'

const debugLog = debug('lint-staged:runAll')

const createError = (ctx) => Object.assign(new Error('lint-staged failed'), { ctx })

/**
 * Executes all tasks and either resolves or rejects the promise
 *
 * @param {object} options
 * @param {boolean} [options.allowEmpty] - Allow empty commits when tasks revert all staged changes
 * @param {boolean | number} [options.concurrent] - The number of tasks to run concurrently, or false to run tasks serially
 * @param {Object} [options.configObject] - Explicit config object from the js API
 * @param {string} [options.configPath] - Explicit path to a config file
 * @param {string} [options.cwd] - Current working directory
 * @param {boolean} [options.debug] - Enable debug mode
 * @param {string} [options.diff] - Override the default "--staged" flag of "git diff" to get list of files
 * @param {string} [options.diffFilter] - Override the default "--diff-filter=ACMR" flag of "git diff" to get list of files
 * @param {number} [options.maxArgLength] - Maximum argument string length
 * @param {boolean} [options.quiet] - Disable lint-staged’s own console output
 * @param {boolean} [options.relative] - Pass relative filepaths to tasks
 * @param {boolean} [options.shell] - Skip parsing of tasks for better shell support
 * @param {boolean} [options.stash] - Enable the backup stash, and revert in case of errors
 * @param {boolean} [options.verbose] - Show task output even when tasks succeed; by default only failed output is shown
 * @param {Logger} logger
 * @returns {Promise}
 */
export const runAll = async (
  {
    allowEmpty = false,
    concurrent = true,
    configObject,
    configPath,
    cwd,
    debug = false,
    diff,
    diffFilter,
    maxArgLength,
    quiet = false,
    relative = false,
    shell = false,
    // Stashing should be disabled by default when the `diff` option is used
    stash = diff === undefined,
    verbose = false,
  },
  logger = console
) => {
  debugLog('Running all linter scripts...')

  // Resolve relative CWD option
  const hasExplicitCwd = !!cwd
  cwd = hasExplicitCwd ? path.resolve(cwd) : process.cwd()
  debugLog('Using working directory `%s`', cwd)

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

  // Lint-staged will create a backup stash only when there's an initial commit,
  // and when using the default list of staged files by default
  ctx.shouldBackup = hasInitialCommit && stash
  if (!ctx.shouldBackup) {
    logger.warn(skippingBackup(hasInitialCommit, diff))
  }

  const files = await getStagedFiles({ cwd: gitDir, diff, diffFilter })
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

  const foundConfigs = await searchConfigs({ configObject, configPath, cwd, gitDir }, logger)
  const numberOfConfigs = Object.keys(foundConfigs).length

  // Throw if no configurations were found
  if (numberOfConfigs === 0) {
    ctx.errors.add(ConfigNotFoundError)
    throw createError(ctx, ConfigNotFoundError)
  }

  const filesByConfig = await groupFilesByConfig({
    configs: foundConfigs,
    files,
    singleConfigMode: configObject || configPath !== undefined,
  })

  const hasMultipleConfigs = numberOfConfigs > 1

  // lint-staged 10 will automatically add modifications to index
  // Warn user when their command includes `git add`
  let hasDeprecatedGitAdd = false

  const listrOptions = {
    ctx,
    exitOnError: false,
    registerSignalListeners: false,
    ...getRenderer({ debug, quiet }, logger),
  }

  const listrTasks = []

  // Set of all staged files that matched a task glob. Values in a set are unique.
  const matchedFiles = new Set()

  for (const [configPath, { config, files }] of Object.entries(filesByConfig)) {
    const configName = configPath ? normalizePath(path.relative(cwd, configPath)) : 'Config object'

    const stagedFileChunks = chunkFiles({ baseDir: gitDir, files, maxArgLength, relative })

    // Use actual cwd if it's specified, or there's only a single config file.
    // Otherwise use the directory of the config file for each config group,
    // to make sure tasks are separated from each other.
    const groupCwd = hasMultipleConfigs && !hasExplicitCwd ? path.dirname(configPath) : cwd

    const chunkCount = stagedFileChunks.length
    if (chunkCount > 1) {
      debugLog('Chunked staged files from `%s` into %d part', configPath, chunkCount)
    }

    for (const [index, files] of stagedFileChunks.entries()) {
      const chunkListrTasks = await Promise.all(
        generateTasks({ config, cwd: groupCwd, files, relative }).map((task) =>
          makeCmdTasks({
            commands: task.commands,
            cwd: groupCwd,
            files: task.fileList,
            gitDir,
            shell,
            verbose,
          }).then((subTasks) => {
            // Add files from task to match set
            task.fileList.forEach((file) => {
              // Make sure relative files are normalized to the
              // group cwd, because other there might be identical
              // relative filenames in the entire set.
              const normalizedFile = path.isAbsolute(file)
                ? file
                : normalizePath(path.join(groupCwd, file))

              matchedFiles.add(normalizedFile)
            })

            hasDeprecatedGitAdd =
              hasDeprecatedGitAdd || subTasks.some((subTask) => subTask.command === 'git add')

            const fileCount = task.fileList.length

            return {
              title: `${task.pattern}${chalk.dim(
                ` — ${fileCount} ${fileCount === 1 ? 'file' : 'files'}`
              )}`,
              task: async (ctx, task) =>
                task.newListr(
                  subTasks,
                  // Subtasks should not run in parallel, and should exit on error
                  { concurrent: false, exitOnError: true }
                ),
              skip: () => {
                // Skip task when no files matched
                if (fileCount === 0) {
                  return `${task.pattern}${chalk.dim(' — no files')}`
                }
                return false
              },
            }
          })
        )
      )

      listrTasks.push({
        title:
          `${configName}${chalk.dim(` — ${files.length} ${files.length > 1 ? 'files' : 'file'}`)}` +
          (chunkCount > 1 ? chalk.dim(` (chunk ${index + 1}/${chunkCount})...`) : ''),
        task: (ctx, task) => task.newListr(chunkListrTasks, { concurrent, exitOnError: true }),
        skip: () => {
          // Skip if the first step (backup) failed
          if (ctx.errors.has(GitError)) return SKIPPED_GIT_ERROR
          // Skip chunk when no every task is skipped (due to no matches)
          if (chunkListrTasks.every((task) => task.skip())) {
            return `${configName}${chalk.dim(' — no tasks to run')}`
          }
          return false
        },
      })
    }
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

  const git = new GitWorkflow({
    allowEmpty,
    gitConfigDir,
    gitDir,
    matchedFileChunks,
    diff,
    diffFilter,
  })

  const runner = new Listr(
    [
      {
        title: 'Preparing lint-staged...',
        task: (ctx) => git.prepare(ctx),
      },
      {
        title: 'Hiding unstaged changes to partially staged files...',
        task: (ctx) => git.hideUnstagedChanges(ctx),
        enabled: hasPartiallyStagedFiles,
      },
      {
        title: `Running tasks for staged files...`,
        task: (ctx, task) => task.newListr(listrTasks, { concurrent }),
        skip: () => listrTasks.every((task) => task.skip()),
      },
      {
        title: 'Applying modifications from tasks...',
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
        title: 'Cleaning up temporary files...',
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
