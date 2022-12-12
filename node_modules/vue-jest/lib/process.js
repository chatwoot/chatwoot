const splitRE = /\r?\n/g

const VueTemplateCompiler = require('vue-template-compiler')
const generateSourceMap = require('./generate-source-map')
const coffeescriptTransformer = require('./transformers/coffee')
const _processStyle = require('./process-style')
const processCustomBlocks = require('./process-custom-blocks')
const getVueJestConfig = require('./utils').getVueJestConfig
const logResultErrors = require('./utils').logResultErrors
const stripInlineSourceMap = require('./utils').stripInlineSourceMap
const getCustomTransformer = require('./utils').getCustomTransformer
const loadSrc = require('./utils').loadSrc
const babelTransformer = require('babel-jest')
const compilerUtils = require('@vue/component-compiler-utils')
const generateCode = require('./generate-code')

function resolveTransformer(lang = 'js', vueJestConfig) {
  const transformer = getCustomTransformer(vueJestConfig['transform'], lang)
  if (/^typescript$|tsx?$/.test(lang)) {
    return transformer || require('./transformers/typescript')
  } else if (/^coffee$|coffeescript$/.test(lang)) {
    return transformer || coffeescriptTransformer
  } else {
    return transformer || babelTransformer
  }
}

function processScript(scriptPart, filePath, config) {
  if (!scriptPart) {
    return null
  }

  let externalSrc = null
  if (scriptPart.src) {
    scriptPart.content = loadSrc(scriptPart.src, filePath)
    externalSrc = scriptPart.content
  }

  const vueJestConfig = getVueJestConfig(config)
  const transformer = resolveTransformer(scriptPart.lang, vueJestConfig)

  const result = transformer.process(scriptPart.content, filePath, config)
  result.code = stripInlineSourceMap(result.code)
  result.externalSrc = externalSrc
  return result
}

function processTemplate(template, filename, config) {
  if (!template) {
    return null
  }

  const vueJestConfig = getVueJestConfig(config)

  if (template.src) {
    template.content = loadSrc(template.src, filename)
  }

  const userTemplateCompilerOptions = vueJestConfig.templateCompiler || {}
  const result = compilerUtils.compileTemplate({
    source: template.content,
    compiler: VueTemplateCompiler,
    filename: filename,
    isFunctional: template.attrs.functional,
    preprocessLang: template.lang,
    preprocessOptions: vueJestConfig[template.lang],
    ...userTemplateCompilerOptions,
    compilerOptions: {
      optimize: false,
      ...userTemplateCompilerOptions.compilerOptions
    }
  })

  logResultErrors(result)

  return result
}

function processStyle(styles, filename, config) {
  if (!styles) {
    return null
  }

  const filteredStyles = styles
    .filter(style => style.module)
    .map(style => ({
      code: _processStyle(style, filename, config),
      moduleName: style.module === true ? '$style' : style.module
    }))

  return filteredStyles.length ? filteredStyles : null
}

module.exports = function(src, filename, config) {
  const descriptor = compilerUtils.parse({
    source: src,
    compiler: VueTemplateCompiler,
    filename
  })

  const templateResult = processTemplate(descriptor.template, filename, config)
  const scriptResult = processScript(descriptor.script, filename, config)
  const stylesResult = processStyle(descriptor.styles, filename, config)
  const customBlocksResult = processCustomBlocks(
    descriptor.customBlocks,
    filename,
    config
  )

  const isFunctional =
    (descriptor.template &&
      descriptor.template.attrs &&
      descriptor.template.attrs.functional) ||
    (descriptor.script &&
      descriptor.script.content &&
      /functional:\s*true/.test(descriptor.script.content))

  const templateStart = descriptor.template && descriptor.template.start
  const templateLine = src.slice(0, templateStart).split(splitRE).length

  const output = generateCode(
    scriptResult,
    templateResult,
    stylesResult,
    customBlocksResult,
    isFunctional
  )

  const map = generateSourceMap(
    scriptResult,
    src,
    filename,
    output.renderFnStartLine,
    output.renderFnEndLine,
    templateLine
  ).toJSON()

  return {
    code: output.code,
    map
  }
}
