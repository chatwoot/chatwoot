#!/usr/bin/env node

import fs from 'node:fs/promises'

import { supportsColor } from 'chalk'
import { Option, program } from 'commander'
import debug from 'debug'

import lintStaged from '../lib/index.js'
import { CONFIG_STDIN_ERROR } from '../lib/messages.js'
import { readStdin } from '../lib/readStdin.js'

// Force colors for packages that depend on https://www.npmjs.com/package/supports-color
if (supportsColor) {
  process.env.FORCE_COLOR = supportsColor.level.toString()
}

// Do not terminate main Listr process on SIGINT
process.on('SIGINT', () => {})

const packageJson = JSON.parse(await fs.readFile(new URL('../package.json', import.meta.url)))
const version = packageJson.version

const debugLog = debug('lint-staged:bin')
debugLog('Running `lint-staged@%s`', version)

const cli = program.version(version)

cli.option('--allow-empty', 'allow empty commits when tasks revert all staged changes', false)

cli.option(
  '-p, --concurrent <number|boolean>',
  'the number of tasks to run concurrently, or false for serial',
  true
)

cli.option('-c, --config [path]', 'path to configuration file, or - to read from stdin')

cli.option('--cwd [path]', 'run all tasks in specific directory, instead of the current')

cli.option('-d, --debug', 'print additional debug information', false)

cli.addOption(
  new Option(
    '--diff [string]',
    'override the default "--staged" flag of "git diff" to get list of files. Implies "--no-stash".'
  ).implies({ stash: false })
)

cli.option(
  '--diff-filter [string]',
  'override the default "--diff-filter=ACMR" flag of "git diff" to get list of files'
)

cli.option('--max-arg-length [number]', 'maximum length of the command-line argument string', 0)

/**
 * We don't want to show the `--stash` flag because it's on by default, and only show the
 * negatable flag `--no-stash` in stead. There seems to be a bug in Commander.js where
 * configuring only the latter won't actually set the default value.
 */
cli
  .addOption(
    new Option('--stash', 'enable the backup stash, and revert in case of errors')
      .default(true)
      .hideHelp()
  )
  .addOption(
    new Option(
      '--no-stash',
      'disable the backup stash, and do not revert in case of errors'
    ).default(false)
  )

cli.option('-q, --quiet', 'disable lint-staged’s own console output', false)

cli.option('-r, --relative', 'pass relative filepaths to tasks', false)

cli.option('-x, --shell [path]', 'skip parsing of tasks for better shell support', false)

cli.option(
  '-v, --verbose',
  'show task output even when tasks succeed; by default only failed output is shown',
  false
)

const cliOptions = cli.parse(process.argv).opts()

if (cliOptions.debug) {
  debug.enable('lint-staged*')
}

const options = {
  allowEmpty: !!cliOptions.allowEmpty,
  concurrent: JSON.parse(cliOptions.concurrent),
  configPath: cliOptions.config,
  cwd: cliOptions.cwd,
  debug: !!cliOptions.debug,
  diff: cliOptions.diff,
  diffFilter: cliOptions.diffFilter,
  maxArgLength: cliOptions.maxArgLength || undefined,
  quiet: !!cliOptions.quiet,
  relative: !!cliOptions.relative,
  shell: cliOptions.shell /* Either a boolean or a string pointing to the shell */,
  stash: !!cliOptions.stash, // commander inverts `no-<x>` flags to `!x`
  verbose: !!cliOptions.verbose,
}

debugLog('Options parsed from command-line:', options)

if (options.configPath === '-') {
  delete options.configPath
  try {
    debugLog('Reading config from stdin')
    options.config = JSON.parse(await readStdin())
  } catch (error) {
    debugLog(CONFIG_STDIN_ERROR, error)
    console.error(CONFIG_STDIN_ERROR)
    process.exit(1)
  }
}

try {
  const passed = await lintStaged(options)
  process.exitCode = passed ? 0 : 1
} catch {
  process.exitCode = 1
}
