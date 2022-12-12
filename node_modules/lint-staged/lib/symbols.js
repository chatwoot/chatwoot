'use strict'

const ApplyEmptyCommitError = Symbol('ApplyEmptyCommitError')
const GetBackupStashError = Symbol('GetBackupStashError')
const GetStagedFilesError = Symbol('GetStagedFilesError')
const GitError = Symbol('GitError')
const GitRepoError = Symbol('GitRepoError')
const HideUnstagedChangesError = Symbol('HideUnstagedChangesError')
const RestoreMergeStatusError = Symbol('RestoreMergeStatusError')
const RestoreOriginalStateError = Symbol('RestoreOriginalStateError')
const RestoreUnstagedChangesError = Symbol('RestoreUnstagedChangesError')
const TaskError = Symbol('TaskError')

module.exports = {
  ApplyEmptyCommitError,
  GetBackupStashError,
  GetStagedFilesError,
  GitError,
  GitRepoError,
  HideUnstagedChangesError,
  RestoreMergeStatusError,
  RestoreOriginalStateError,
  RestoreUnstagedChangesError,
  TaskError,
}
