let { bold: b, red, yellow: y } = require('picocolors')
let { existsSync } = require('fs')
let { join } = require('path')

let ownPackage = require('./package.json')

function npmCommands(pkg) {
  let add = 'npm install --save-dev '
  let rm = 'npm remove '
  if (existsSync(join(pkg.path, '..', 'yarn.lock'))) {
    add = 'yarn add --dev '
    rm = 'yarn remove '
  } else if (existsSync(join(pkg.path, '..', 'pnpm-lock.yaml'))) {
    add = 'pnpm add --save-dev '
    rm = 'pnpm remove '
  }
  return { add, rm }
}

module.exports = process => {
  function print(...lines) {
    process.stdout.write(lines.join('\n') + '\n')
  }
  function printError(...lines) {
    process.stderr.write(lines.join('\n') + '\n')
  }

  function showHelp(plugins) {
    print(
      y('size-limit [OPTION]… [FILE]…'),
      'Check the real performance cost of your front-end project to users',
      '',
      b('Core options:'),
      `  ${y('--limit LIMIT')}     Set size or running time limit for files`,
      `  ${y('--json')}            Show results in JSON format`,
      `  ${y('--hide-passed')}     Print only failed files`,
      `  ${y('--highlight-less')}  Highlight files with less than limit size`,
      `  ${y('--help')}            Display this help`,
      `  ${y('--watch')}           Runs in watch mode`,
      `  ${y('--silent')}          Show only failed limits`,
      `  ${y('--debug')}           Show internal configs for issue report`,
      `  ${y('--version')}         Display version`
    )
    if (plugins.has('webpack')) {
      print(
        '',
        b('Webpack options:'),
        `  ${y('--why')}              Show package content`,
        `  ${y('--compare-with')}     Path to stats.json from another build` +
          ` to compare`,
        `  ${y('--save-bundle DIR')}  Put build files to check them by hand`,
        `  ${y('--clean-dir')}        Remove build files folder before start`
      )
    }
    print(
      '',
      b('Examples:'),
      '  ' + y('size-limit'),
      `    Read configuration from ${b('package.json')} or ` +
        `${b('.size-limit.json')} and check limit`,
      y('  size-limit index.js')
    )
    if (plugins.has('webpack')) {
      print(
        '    Show the size of specific files with all file dependencies',
        '  ' + y('size-limit --why'),
        '    Show reasons why project have this size'
      )
    } else {
      print('    Show the size of specific files')
    }
  }

  function showVersion() {
    print(`size-limit ${ownPackage.version}`)
  }

  function showMigrationGuide(pkg) {
    let { add } = npmCommands(pkg)
    printError(
      red('Install Size Limit preset depends on type of the project'),
      '',
      'For application, where you send JS bundle directly to users',
      '  ' + y(add + '@size-limit/preset-app'),
      '',
      'For frameworks, components and big libraries',
      '  ' + y(add + '@size-limit/preset-big-lib'),
      '',
      'For small (< 10 kB) libraries',
      '  ' + y(add + '@size-limit/preset-small-lib'),
      '',
      'Check out docs for more complicated cases',
      '  ' + y('https://github.com/ai/size-limit/')
    )
    let devDependencies = pkg.packageJson.devDependencies
    if (devDependencies && !devDependencies['size-limit']) {
      printError(
        '',
        `You need to add size-limit dependency: ${y(add + 'size-limit')}`
      )
    }
  }

  return { showHelp, showMigrationGuide, showVersion }
}
