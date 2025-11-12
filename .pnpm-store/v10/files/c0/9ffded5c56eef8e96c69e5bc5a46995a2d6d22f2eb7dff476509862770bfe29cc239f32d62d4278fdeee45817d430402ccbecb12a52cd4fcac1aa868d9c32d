let {
  bgGreen,
  bgRed,
  black,
  bold,
  gray,
  green,
  red,
  yellow
} = require('picocolors')
let { join } = require('path')
let bytes = require('bytes-iec')

function createJsonReporter(process) {
  function print(data) {
    process.stdout.write(JSON.stringify(data, null, 2) + '\n')
  }

  return {
    error(err) {
      print({ error: err.stack })
    },

    results(plugins, config) {
      print(
        config.checks.map(i => {
          let result = { name: i.name }
          if (typeof i.passed !== 'undefined') result.passed = i.passed
          if (typeof i.size !== 'undefined') result.size = i.size
          if (typeof i.limit !== 'undefined') result.sizeLimit = i.sizeLimit
          if (typeof i.runTime !== 'undefined') result.running = i.runTime
          if (typeof i.loadTime !== 'undefined') result.loading = i.loadTime
          return result
        })
      )
    }
  }
}

function getFixText(prefix, config) {
  if (config.configPath) {
    if (config.configPath.endsWith('package.json')) {
      prefix += ` in ${bold('"size-limit"')} section of `
    } else {
      prefix += ' at '
    }
    prefix += bold(config.configPath)
  }

  return prefix
}

function createHumanReporter(process, isSilentMode = false) {
  function print(...lines) {
    process.stdout.write('  ' + lines.join('\n  ') + '\n')
  }

  function formatBytes(size) {
    return bytes.format(size, { unitSeparator: ' ' })
  }

  function formatTime(seconds) {
    if (seconds >= 1) {
      return Math.ceil(seconds * 10) / 10 + ' s'
    } else {
      return Math.ceil(seconds * 1000) + ' ms'
    }
  }

  return {
    error(err) {
      if (err.name === 'SizeLimitError') {
        let msg = err.message
          .split('. ')
          .map(i => i.replace(/\*([^*]+)\*/g, yellow('$1')))
          .join('.\n        ')
        process.stderr.write(`${bgRed(black(' ERROR '))} ${red(msg)}\n`)
        if (err.example) {
          process.stderr.write(
            '\n' +
              err.example
                .replace(/("[^"]+"):/g, green('$1') + ':')
                .replace(/: ("[^"]+")/g, ': ' + yellow('$1'))
          )
        }
      } else {
        process.stderr.write(`${bgRed(black(' ERROR '))} ${red(err.stack)}\n`)
      }
    },

    results(plugins, config) {
      print('')
      for (let check of config.checks) {
        if (
          (check.passed && config.hidePassed && !isSilentMode) ||
          (isSilentMode && check.passed !== false)
        ) {
          continue
        }

        let unlimited = typeof check.passed === 'undefined'
        let rows = []

        if (config.checks.length > 1) {
          print(bold(check.name))
        }

        if (check.missed) {
          print(red(`Size Limit can’t find files at ${check.path}`))
          continue
        }

        let sizeNote
        let bundled = plugins.has('webpack') || plugins.has('esbuild')
        if (check.config) {
          sizeNote = 'with given webpack configuration'
        } else if (bundled && check.brotli === true) {
          sizeNote = 'with all dependencies, minified and brotlied'
        } else if (bundled && check.gzip === false) {
          sizeNote = 'with all dependencies and minified'
        } else if (bundled) {
          sizeNote = 'with all dependencies, minified and gzipped'
        } else if (plugins.has('file') && check.brotli === true) {
          sizeNote = 'brotlied'
        } else if (plugins.has('file') && check.gzip !== false) {
          sizeNote = 'gzipped'
        }
        let sizeString = formatBytes(check.size)

        if (typeof check.timeLimit !== 'undefined') {
          if (check.passed === false) {
            print(red('Total time limit has exceeded'))
          }
          rows.push(['Time limit', formatTime(check.timeLimit)])
        }
        if (typeof check.sizeLimit !== 'undefined') {
          let sizeLimitString = formatBytes(check.sizeLimit)
          if (check.passed === false) {
            if (sizeLimitString === sizeString) {
              sizeLimitString = check.sizeLimit + ' B'
              sizeString = check.size + ' B'
            }
            let diff = formatBytes(check.size - check.sizeLimit)
            print(red(`Package size limit has exceeded by ${diff}`))
          } else if (check.highlightLess && check.size < check.sizeLimit) {
            let diff = formatBytes(check.sizeLimit - check.size)
            print(bgGreen(black(`Package size is ${diff} less than limit`)))
          }
          rows.push(['Size limit', sizeLimitString])
        }

        if (typeof check.size !== 'undefined') {
          rows.push(['Size', sizeString, sizeNote])
        }
        if (typeof check.loadTime !== 'undefined') {
          rows.push(['Loading time', formatTime(check.loadTime), 'on slow 3G'])
        }
        if (typeof check.runTime !== 'undefined') {
          rows.push(
            ['Running time', formatTime(check.runTime), 'on Snapdragon 410'],
            ['Total time', formatTime(check.time)]
          )
        }

        let max0 = Math.max(...rows.map(row => row[0].length))
        let max1 = Math.max(...rows.map(row => row[1].length))

        for (let [name, value, note] of rows) {
          let str = (name + ':').padEnd(max0 + 1) + ' '
          if (note) value = value.padEnd(max1)
          value = bold(value)
          if (unlimited || name.includes('Limit')) {
            str += value
          } else if (check.passed) {
            str += green(value)
          } else {
            str += red(value)
          }
          if (note) {
            str += ' ' + gray(note)
          }
          print(str)
        }
        print('')
      }

      if (config.failed) {
        let fix = getFixText('Try to reduce size or increase limit', config)
        print(yellow(fix))
      }

      if (plugins.has('webpack') && config.saveBundle) {
        let statsFilepath = join(config.saveBundle, 'stats.json')
        print(`Webpack Stats file was saved to ${statsFilepath}`)
        print('You can review it using https://webpack.github.io/analyse')
      }
    }
  }
}

module.exports = (process, isJSON, isSilentMode) => {
  if (isJSON) {
    return createJsonReporter(process)
  } else {
    return createHumanReporter(process, isSilentMode)
  }
}
