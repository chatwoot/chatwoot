import { inspect } from 'node:util'

import chalk from 'chalk'

import { error, info, warning } from './figures.js'

export const configurationError = (opt, helpMsg, value) =>
  `${chalk.redBright(`${error} Validation Error:`)}

  Invalid value for '${chalk.bold(opt)}': ${chalk.bold(inspect(value))}

  ${helpMsg}`

export const NOT_GIT_REPO = chalk.redBright(`${error} Current directory is not a git directory!`)

export const FAILED_GET_STAGED_FILES = chalk.redBright(`${error} Failed to get staged files!`)

export const incorrectBraces = (before, after) =>
  chalk.yellow(
    `${warning} Detected incorrect braces with only single value: \`${before}\`. Reformatted as: \`${after}\`
`
  )

export const NO_CONFIGURATION = `${error} No valid configuration found.`

export const NO_STAGED_FILES = `${info} No staged files found.`

export const NO_TASKS = `${info} No staged files match any configured task.`

export const skippingBackup = (hasInitialCommit, diff) => {
  const reason =
    diff !== undefined
      ? '`--diff` was used'
      : hasInitialCommit
      ? '`--no-stash` was used'
      : 'there’s no initial commit yet'

  return chalk.yellow(`${warning} Skipping backup because ${reason}.\n`)
}

export const DEPRECATED_GIT_ADD = chalk.yellow(
  `${warning} Some of your tasks use \`git add\` command. Please remove it from the config since all modifications made by tasks will be automatically added to the git commit index.
`
)

export const TASK_ERROR = 'Skipped because of errors from tasks.'

export const SKIPPED_GIT_ERROR = 'Skipped because of previous git error.'

export const GIT_ERROR = `\n  ${chalk.redBright(`${error} lint-staged failed due to a git error.`)}`

export const invalidOption = (name, value, message) => `${chalk.redBright(
  `${error} Validation Error:`
)}

  Invalid value for option '${chalk.bold(name)}': ${chalk.bold(value)}

  ${message}

See https://github.com/okonet/lint-staged#command-line-flags`

export const PREVENTED_EMPTY_COMMIT = `
  ${chalk.yellow(`${warning} lint-staged prevented an empty git commit.
  Use the --allow-empty option to continue, or check your task configuration`)}
`

export const RESTORE_STASH_EXAMPLE = `  Any lost modifications can be restored from a git stash:

    > git stash list
    stash@{0}: automatic lint-staged backup
    > git stash apply --index stash@{0}
`

export const CONFIG_STDIN_ERROR = chalk.redBright(`${error} Failed to read config from stdin.`)
