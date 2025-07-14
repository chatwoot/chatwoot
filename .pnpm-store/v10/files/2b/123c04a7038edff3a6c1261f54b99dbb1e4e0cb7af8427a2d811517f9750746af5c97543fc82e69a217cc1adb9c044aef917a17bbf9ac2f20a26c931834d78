const MESSAGES = {
  argWithoutAnalyzer: (arg, bundler, analyzer = `${bundler}-${arg}`) =>
    `Argument *--${arg}* works only with *@size-limit/${bundler}* plugin` +
    ` and *@size-limit/${analyzer}* plugin. You can add Bundle ` +
    `Analyzer to you own bundler.`,
  argWithoutAnotherArg: (arg, anotherArg) =>
    `Argument *--${arg}* works only with *--${anotherArg}* argument`,
  argWithoutParameter: (arg, parameter) =>
    `Missing parameter *${parameter}* for *--${arg}* argument`,
  argWithoutPlugins: (arg, mod1, mod2) =>
    `Argument *--${arg}* needs *@size-limit/${mod1}* ` +
    `or *@size-limit/${mod2}* plugin`,
  brotliUnsupported: () =>
    'Update your Node.js to version >= v11.7.0 to use Brotli',
  bundleDirNotEmpty: dir =>
    `The directory *${dir}* is not empty. ` +
    'Pass *--clean-dir* if you want to remove it',
  cmdError: (cmd, error) => (error ? `${cmd} error: ${error}` : `${cmd} error`),
  emptyConfig: () => 'Size Limit config must *not be empty*',
  entryNotString: () =>
    'The *entry* in Size Limit config ' +
    'must be *a string* or *an array of strings*',
  missedPlugin: mod => `Add *@size-limit/${mod}* plugin to Size Limit`,
  multiPluginlessConfig: (opt, mod1, mod2) =>
    `Config option *${opt}* needs *@size-limit/${mod1}* ` +
    `or *@size-limit/${mod2}* plugin`,
  noArrayConfig: () => 'Size Limit config must contain *an array*',
  noConfig: () => 'Create Size Limit config in *package.json*',
  noObjectCheck: () => 'Size Limit config array should contain *only objects*',
  noPackage: () =>
    'Size Limit didn’t find *package.json*. ' +
    'Create npm package and run Size Limit there.',
  pathNotString: () =>
    'The *path* in Size Limit config ' +
    'must be *a string* or *an array of strings*',
  pluginlessConfig: (opt, mod) =>
    `Config option *${opt}* needs *@size-limit/${mod}* plugin`,
  timeWithoutPlugin: () => 'Add *@size-limit/time* plugin to use time limit',
  unknownArg: arg =>
    `Unknown argument *${arg}*. Check command for typo and read docs.`,
  unknownEntry: entry =>
    `Size Limit didn’t find *${entry}* entry in custom Webpack config`,
  unknownOption: opt =>
    `Unknown option *${opt}* in config. Check Size Limit docs and version.`
}

const ADD_CONFIG_EXAMPLE = {
  emptyConfig: true,
  noArrayConfig: true,
  noConfig: true,
  noObjectCheck: true,
  pathNotString: true
}

class SizeLimitError extends Error {
  constructor(type, ...args) {
    super(MESSAGES[type](...args))
    this.name = 'SizeLimitError'
    if (ADD_CONFIG_EXAMPLE[type]) {
      this.example =
        '  "size-limit": [\n' +
        '    {\n' +
        '      "path": "dist/bundle.js",\n' +
        '      "limit": "10 kB"\n' +
        '    }\n' +
        '  ]\n'
    }
  }
}

module.exports = SizeLimitError
