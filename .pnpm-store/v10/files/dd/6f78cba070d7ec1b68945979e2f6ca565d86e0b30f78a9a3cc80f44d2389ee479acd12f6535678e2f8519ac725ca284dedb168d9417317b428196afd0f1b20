import EventEmitter from 'events'

import { GIT_ERROR, TASK_ERROR } from './messages.js'
import {
  ApplyEmptyCommitError,
  TaskError,
  RestoreOriginalStateError,
  GitError,
  RestoreUnstagedChangesError,
} from './symbols.js'

export const getInitialState = ({ quiet = false } = {}) => ({
  hasPartiallyStagedFiles: null,
  shouldBackup: null,
  errors: new Set([]),
  events: new EventEmitter(),
  output: [],
  quiet,
})

export const hasPartiallyStagedFiles = (ctx) => ctx.hasPartiallyStagedFiles

export const applyModificationsSkipped = (ctx) => {
  // Always apply back unstaged modifications when skipping backup
  if (!ctx.shouldBackup) return false
  // Should be skipped in case of git errors
  if (ctx.errors.has(GitError)) {
    return GIT_ERROR
  }
  // Should be skipped when tasks fail
  if (ctx.errors.has(TaskError)) {
    return TASK_ERROR
  }
}

export const restoreUnstagedChangesSkipped = (ctx) => {
  // Should be skipped in case of git errors
  if (ctx.errors.has(GitError)) {
    return GIT_ERROR
  }
  // Should be skipped when tasks fail
  if (ctx.errors.has(TaskError)) {
    return TASK_ERROR
  }
}

export const restoreOriginalStateEnabled = (ctx) =>
  ctx.shouldBackup &&
  (ctx.errors.has(TaskError) ||
    ctx.errors.has(ApplyEmptyCommitError) ||
    ctx.errors.has(RestoreUnstagedChangesError))

export const restoreOriginalStateSkipped = (ctx) => {
  // Should be skipped in case of unknown git errors
  if (
    ctx.errors.has(GitError) &&
    !ctx.errors.has(ApplyEmptyCommitError) &&
    !ctx.errors.has(RestoreUnstagedChangesError)
  ) {
    return GIT_ERROR
  }
}

export const cleanupEnabled = (ctx) => ctx.shouldBackup

export const cleanupSkipped = (ctx) => {
  // Should be skipped in case of unknown git errors
  if (
    ctx.errors.has(GitError) &&
    !ctx.errors.has(ApplyEmptyCommitError) &&
    !ctx.errors.has(RestoreUnstagedChangesError)
  ) {
    return GIT_ERROR
  }
  // Should be skipped when reverting to original state fails
  if (ctx.errors.has(RestoreOriginalStateError)) {
    return GIT_ERROR
  }
}
