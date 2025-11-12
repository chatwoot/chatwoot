let SizeLimitError = require('./size-limit-error')

module.exports = function parseArgs(plugins, argv) {
  let args = { files: [] }
  for (let i = 2; i < argv.length; i++) {
    let arg = argv[i]

    if (arg === '--limit') {
      args.limit = argv[++i]
    } else if (arg === '--debug') {
      args.debug = true
    } else if (arg === '--save-bundle') {
      if (!plugins.has('esbuild') && !plugins.has('webpack')) {
        throw new SizeLimitError(
          'argWithoutPlugins',
          'save-bundle',
          'webpack',
          'esbuild'
        )
      }
      let nextArg = argv[++i]
      if (!nextArg || nextArg.startsWith('--')) {
        throw new SizeLimitError('argWithoutParameter', 'save-bundle', 'DIR')
      }
      args.saveBundle = nextArg
    } else if (arg === '--clean-dir') {
      if (!argv.includes('--save-bundle')) {
        throw new SizeLimitError(
          'argWithoutAnotherArg',
          'clean-dir',
          'save-bundle'
        )
      }
      args.cleanDir = true
    } else if (arg === '--hide-passed') {
      args.hidePassed = true
    } else if (arg === '--why') {
      if (plugins.has('esbuild')) {
        if (!plugins.has('esbuild-why')) {
          throw new SizeLimitError('argWithoutAnalyzer', 'why', 'esbuild')
        }
      }
      // current code assume either esbuild or webpack must be present.
      // this should be improved to work with any bundler.
      else if (!plugins.has('webpack') || !plugins.has('webpack-why')) {
        throw new SizeLimitError('argWithoutAnalyzer', 'why', 'webpack')
      }
      args.why = true
    } else if (arg === '--compare-with') {
      if (!plugins.has('webpack') || !plugins.has('webpack-why')) {
        throw new SizeLimitError('argWithoutAnalyzer', 'compare-with', 'webpack', 'webpack-why')
      }
      if (!args.why) {
        throw new SizeLimitError('argWithoutAnotherArg', 'compare-with', 'why')
      }
      let nextArg = argv[++i]
      if (!nextArg || nextArg.startsWith('--')) {
        throw new SizeLimitError('argWithoutParameter', 'compare-with', 'FILE')
      }
      args.compareWith = nextArg
    } else if (arg === '--watch') {
      /* istanbul ignore next */
      args.watch = true
    } else if (arg === '--highlight-less') {
      args.highlightLess = true
    } else if (arg[0] !== '-') {
      args.files.push(arg)
    } else if (arg === '--silent') {
      args.isSilentMode = arg
    } else if (arg !== '--json') {
      throw new SizeLimitError('unknownArg', arg)
    }
  }
  return args
}
