let { createSpinner } = require('nanospinner')
let { resolve } = require('path')
let chokidar = require('chokidar')

let SizeLimitError = require('./size-limit-error')
let createReporter = require('./create-reporter')
let loadPlugins = require('./load-plugins')
let createHelp = require('./create-help')
let readPkgUp = require('./read-pkg-up')
let getConfig = require('./get-config')
let parseArgs = require('./parse-args')
let debug = require('./debug')
let calc = require('./calc')

function throttle(fn) {
  let next, running
  // istanbul ignore next
  return () => {
    clearTimeout(next)
    next = setTimeout(async () => {
      await running
      running = fn()
    }, 200)
  }
}

async function findPlugins(parentPkg) {
  let plugins = loadPlugins(parentPkg)

  if (!parentPkg || !plugins.isEmpty) return plugins
  if (parentPkg.packageJson && parentPkg.packageJson.sizeLimitRoot) {
    return plugins
  }

  let cwd = resolve(parentPkg.path, '..', '..')
  let pkg = await readPkgUp(cwd)

  return findPlugins(pkg)
}

module.exports = async process => {
  function hasArg(arg) {
    return process.argv.includes(arg)
  }
  let isJsonOutput = hasArg('--json')
  let isSilentMode = hasArg('--silent')
  let reporter = createReporter(process, isJsonOutput, isSilentMode)
  let help = createHelp(process)
  let config, args

  try {
    if (hasArg('--version')) {
      return help.showVersion()
    }

    let pkg = await readPkgUp(process.cwd())
    let plugins = await findPlugins(pkg)

    if (hasArg('--help')) {
      return help.showHelp(plugins)
    }

    if (!pkg || !pkg.packageJson) {
      throw new SizeLimitError('noPackage')
    }

    args = parseArgs(plugins, process.argv)

    if (plugins.isEmpty) {
      help.showMigrationGuide(pkg)
      return process.exit(1)
    }

    config = await getConfig(plugins, process, args, pkg)

    let calcAndShow = async () => {
      let outputFunc = isJsonOutput || isSilentMode ? null : createSpinner
      await calc(plugins, config, outputFunc)
      debug.results(process, args, config)
      reporter.results(plugins, config)
    }

    await calcAndShow()

    /* istanbul ignore if */
    if (hasArg('--watch')) {
      let watcher = chokidar.watch(['**/*'], {
        ignored: '**/node_modules/**'
      })
      watcher.on('change', throttle(calcAndShow))
    }

    if ((config.failed || config.missed) && !args.why) process.exit(1)
  } catch (e) {
    debug.error(process, args, config)
    reporter.error(e)
    process.exit(1)
  }
}
