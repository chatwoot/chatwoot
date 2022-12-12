const constants = require('./constants')
const loadPartialConfig = require('@babel/core').loadPartialConfig
const chalk = require('chalk')
const path = require('path')
const fs = require('fs')

const fetchTransformer = function fetchTransformer(key, obj) {
  for (const exp in obj) {
    const matchKey = new RegExp(exp)
    if (matchKey.test(key)) {
      return obj[exp]
    }
  }
  return null
}

const resolvePath = function resolvePath(pathToResolve) {
  return /^(\.\.\/|\.\/|\/)/.test(pathToResolve)
    ? path.resolve(process.cwd(), pathToResolve)
    : pathToResolve
}

const info = function info(msg) {
  console.info(chalk.blue('\n[vue-jest]: ' + msg + '\n'))
}

const warn = function warn(msg) {
  console.warn(chalk.red('\n[vue-jest]: ' + msg + '\n'))
}

const transformContent = function transformContent(
  content,
  filePath,
  config,
  transformer,
  attrs
) {
  if (!transformer) {
    return content
  }
  try {
    return transformer(content, filePath, config, attrs)
  } catch (err) {
    warn(`There was an error while compiling ${filePath} ${err}`)
  }
  return content
}

const getVueJestConfig = function getVueJestConfig(jestConfig) {
  return (
    (jestConfig && jestConfig.globals && jestConfig.globals['vue-jest']) || {}
  )
}
const getBabelOptions = function loadBabelOptions(filename, options = {}) {
  const opts = Object.assign(options, {
    caller: {
      name: 'vue-jest',
      supportsStaticESM: false
    },
    filename,
    sourceMaps: 'both'
  })
  return loadPartialConfig(opts).options
}

const getTsJestConfig = function getTsJestConfig(config) {
  const createTransformer = require('ts-jest').createTransformer
  const tr = createTransformer()
  const configSet = tr.configsFor(config)
  var tsConfig = configSet.typescript || configSet.parsedTsConfig
  return { compilerOptions: tsConfig.options }
}

function isValidTransformer(transformer) {
  return (
    isFunction(transformer.process) ||
    isFunction(transformer.postprocess) ||
    isFunction(transformer.preprocess)
  )
}

const isFunction = fn => typeof fn === 'function'

const getCustomTransformer = function getCustomTransformer(
  transform = {},
  lang
) {
  transform = { ...constants.defaultVueJestConfig.transform, ...transform }

  const transformerPath = fetchTransformer(lang, transform)

  if (!transformerPath) {
    return null
  }

  let transformer
  if (
    typeof transformerPath === 'string' &&
    require(resolvePath(transformerPath))
  ) {
    transformer = require(resolvePath(transformerPath))
  } else if (typeof transformerPath === 'object') {
    transformer = transformerPath
  }

  if (!isValidTransformer(transformer)) {
    throwError(
      `transformer must contain at least one process, preprocess, or ` +
        `postprocess method`
    )
  }

  return transformer
}

const throwError = function error(msg) {
  throw new Error('\n[vue-jest] Error: ' + msg + '\n')
}

const stripInlineSourceMap = function(str) {
  return str.slice(0, str.indexOf('//# sourceMappingURL'))
}

const logResultErrors = result => {
  if (result.errors.length) {
    result.errors.forEach(function(msg) {
      console.error('\n' + chalk.red(msg) + '\n')
    })
    throwError('Vue template compilation failed')
  }
}

const loadSrc = (src, filePath) => {
  var dir = path.dirname(filePath)
  var srcPath = path.resolve(dir, src)
  try {
    return fs.readFileSync(srcPath, 'utf-8')
  } catch (e) {
    throwError(
      'Failed to load src: "' + src + '" from file: "' + filePath + '"'
    )
  }
}

module.exports = {
  stripInlineSourceMap,
  throwError,
  logResultErrors,
  getCustomTransformer,
  getTsJestConfig,
  getBabelOptions,
  getVueJestConfig,
  transformContent,
  info,
  warn,
  resolvePath,
  fetchTransformer,
  loadSrc
}
