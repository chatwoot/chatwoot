const unified = require('unified')
const toMDAST = require('remark-parse')
const remarkMdx = require('remark-mdx')
const footnotes = require('remark-footnotes')
const squeeze = require('remark-squeeze-paragraphs')
const visit = require('unist-util-visit')
const raw = require('hast-util-raw')
const toMDXAST = require('./md-ast-to-mdx-ast')
const mdxAstToMdxHast = require('./mdx-ast-to-mdx-hast')
const mdxHastToJsx = require('./mdx-hast-to-jsx')

const DEFAULT_OPTIONS = {
  remarkPlugins: [],
  rehypePlugins: [],
  compilers: []
}

function createMdxAstCompiler(options) {
  const mdPlugins = options.mdPlugins
  const remarkPlugins = options.remarkPlugins
  const plugins = mdPlugins || remarkPlugins

  if (mdPlugins) {
    console.error(`
      @mdx-js/mdx: The mdPlugins option has been deprecated in favor of remarkPlugins
                   Support for mdPlugins will be removed in MDX v2
    `)
  }

  const fn = unified()
    .use(toMDAST, options)
    .use(remarkMdx, options)
    .use(footnotes, options)
    .use(squeeze, options)
    .use(toMDXAST, options)

  plugins.forEach(plugin => {
    // Handle [plugin, pluginOptions] syntax
    if (Array.isArray(plugin) && plugin.length > 1) {
      fn.use(plugin[0], plugin[1])
    } else {
      fn.use(plugin)
    }
  })

  fn.use(mdxAstToMdxHast, options)

  return fn
}

function applyHastPluginsAndCompilers(compiler, options) {
  const hastPlugins = options.hastPlugins
  const rehypePlugins = options.rehypePlugins
  const plugins = hastPlugins || rehypePlugins

  if (hastPlugins) {
    console.error(`
      @mdx-js/mdx: The hastPlugins option has been deprecated in favor of rehypePlugins
                   Support for hastPlugins will be removed in MDX v2
    `)
  }

  const compilers = options.compilers

  // Convert raw nodes into HAST
  compiler.use(() => ast => {
    visit(ast, 'raw', node => {
      const {children, tagName, properties} = raw(node)
      node.type = 'element'
      node.children = children
      node.tagName = tagName

      node.properties = properties
    })
  })

  plugins.forEach(plugin => {
    // Handle [plugin, pluginOptions] syntax
    if (Array.isArray(plugin) && plugin.length > 1) {
      compiler.use(plugin[0], plugin[1])
    } else {
      compiler.use(plugin)
    }
  })

  compiler.use(mdxHastToJsx, options)

  for (const compilerPlugin of compilers) {
    compiler.use(compilerPlugin, options)
  }

  return compiler
}

function createCompiler(options = {}) {
  const opts = Object.assign({}, DEFAULT_OPTIONS, options)
  const compiler = createMdxAstCompiler(opts)
  const compilerWithPlugins = applyHastPluginsAndCompilers(compiler, opts)

  return compilerWithPlugins
}

function sync(mdx, options = {}) {
  const compiler = createCompiler(options)

  const fileOpts = {contents: mdx}
  if (options.filepath) {
    fileOpts.path = options.filepath
  }

  const {contents} = compiler.processSync(fileOpts)

  return `/* @jsxRuntime classic */
/* @jsx mdx */
${contents}`
}

async function compile(mdx, options = {}) {
  const compiler = createCompiler(options)

  const fileOpts = {contents: mdx}
  if (options.filepath) {
    fileOpts.path = options.filepath
  }

  const {contents} = await compiler.process(fileOpts)

  return `/* @jsxRuntime classic */
/* @jsx mdx */
${contents}`
}

compile.sync = sync

module.exports = compile
exports = compile
exports.sync = sync
exports.createMdxAstCompiler = createMdxAstCompiler
exports.createCompiler = createCompiler
exports.default = compile
