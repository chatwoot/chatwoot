const {transformSync} = require('@babel/core')
const styleToObject = require('style-to-object')
const camelCaseCSS = require('camelcase-css')
const uniq = require('lodash.uniq')
const {paramCase, toTemplateLiteral} = require('@mdx-js/util')
const BabelPluginApplyMdxProp = require('babel-plugin-apply-mdx-type-prop')
const BabelPluginExtractImportNames = require('babel-plugin-extract-import-names')

// From https://github.com/wooorm/property-information/blob/ca74feb1fcd40753367c75b63c893353cd7d8c70/lib/html.js
const spaceSeparatedProperties = [
  'acceptCharset',
  'accessKey',
  'autoComplete',
  'className',
  'controlsList',
  'headers',
  'htmlFor',
  'httpEquiv',
  'itemProp',
  'itemRef',
  'itemType',
  'ping',
  'rel',
  'sandbox'
]

// eslint-disable-next-line complexity
function toJSX(node, parentNode = {}, options = {}) {
  const {
    // Default options
    skipExport = false,
    preserveNewlines = false,
    wrapExport
  } = options
  let children = ''

  if (node.properties != null) {
    // Turn style strings into JSX-friendly style object
    if (typeof node.properties.style === 'string') {
      let styleObject = {}
      styleToObject(node.properties.style, function (name, value) {
        styleObject[camelCaseCSS(name)] = value
      })
      node.properties.style = styleObject
    }

    // Transform class property to JSX-friendly className
    if (node.properties.class) {
      node.properties.className = node.properties.class
      delete node.properties.class
    }

    // AriaProperty => aria-property
    // dataProperty => data-property
    const paramCaseRe = /^(aria[A-Z])|(data[A-Z])/
    node.properties = Object.entries(node.properties).reduce(
      (properties, [key, value]) =>
        Object.assign({}, properties, {
          [paramCaseRe.test(key) ? paramCase(key) : key]: value
        }),
      {}
    )
  }

  if (node.type === 'root') {
    const importNodes = []
    const exportNodes = []
    const jsxNodes = []
    let layout
    for (const childNode of node.children) {
      if (childNode.type === 'import') {
        importNodes.push(childNode)
        continue
      }

      if (childNode.type === 'export') {
        if (childNode.default) {
          layout = childNode.value
            .replace(/^export\s+default\s+/, '')
            .replace(/;\s*$/, '')
          continue
        }

        exportNodes.push(childNode)
        continue
      }

      jsxNodes.push(childNode)
    }

    const exportNames = exportNodes
      .map(node =>
        node.value.match(/^export\s*(var|const|let|class|function)?\s*(\w+)/)
      )
      .map(match => (Array.isArray(match) ? match[2] : null))
      .filter(Boolean)

    const importStatements = importNodes
      .map(childNode => toJSX(childNode, node))
      .join('\n')
    const exportStatements = exportNodes
      .map(childNode => toJSX(childNode, node))
      .join('\n')
    const layoutProps = `const layoutProps = {
  ${exportNames.join(',\n')}
};`
    const mdxLayout = `const MDXLayout = ${layout ? layout : '"wrapper"'}`

    const fn = `function MDXContent({ components, ...props }) {
  return (
    <MDXLayout
      {...layoutProps}
      {...props}
      components={components}>
${jsxNodes.map(childNode => toJSX(childNode, node)).join('')}
    </MDXLayout>
  )
};
MDXContent.isMDXComponent = true`

    // Check JSX nodes against imports
    const babelPluginExtractImportNamesInstance = new BabelPluginExtractImportNames()
    const filename = options.file && options.file.path
    transformSync(importStatements, {
      filename,
      configFile: false,
      babelrc: false,
      plugins: [
        require('@babel/plugin-syntax-jsx'),
        require('@babel/plugin-syntax-object-rest-spread'),
        babelPluginExtractImportNamesInstance.plugin
      ]
    })
    const importNames = babelPluginExtractImportNamesInstance.state.names

    const babelPluginApplyMdxPropInstance = new BabelPluginApplyMdxProp()
    const babelPluginApplyMdxPropToExportsInstance = new BabelPluginApplyMdxProp()

    const fnPostMdxTypeProp = transformSync(fn, {
      filename,
      configFile: false,
      babelrc: false,
      plugins: [
        require('@babel/plugin-syntax-jsx'),
        require('@babel/plugin-syntax-object-rest-spread'),
        babelPluginApplyMdxPropInstance.plugin
      ]
    }).code

    const exportStatementsPostMdxTypeProps = transformSync(exportStatements, {
      filename,
      configFile: false,
      babelrc: false,
      plugins: [
        require('@babel/plugin-syntax-jsx'),
        require('@babel/plugin-syntax-object-rest-spread'),
        babelPluginApplyMdxPropToExportsInstance.plugin
      ]
    }).code

    const allJsxNames = [
      ...babelPluginApplyMdxPropInstance.state.names,
      ...babelPluginApplyMdxPropToExportsInstance.state.names
    ]
    const jsxNames = allJsxNames.filter(name => name !== 'MDXLayout')

    const importExportNames = importNames.concat(exportNames)
    const shortCodeDef = `const makeShortcode = name => function MDXDefaultShortcode(props) {
      console.warn("Component " + name + " was not imported, exported, or provided by MDXProvider as global scope")
      return <div {...props}/>
    };
`
    const fakedModulesForGlobalScope = uniq(jsxNames)
      .filter(name => !importExportNames.includes(name))
      .map(name => `const ${name} = makeShortcode("${name}");`)
      .join('\n')
    const fakedModules =
      (fakedModulesForGlobalScope &&
        [shortCodeDef, fakedModulesForGlobalScope].join('')) ||
      ''

    const moduleBase = `${importStatements}
${exportStatementsPostMdxTypeProps}
${fakedModules}
${layoutProps}
${mdxLayout}`

    if (skipExport) {
      return `${moduleBase}
${fnPostMdxTypeProp}`
    }

    if (wrapExport) {
      return `${moduleBase}
${fnPostMdxTypeProp}
export default ${wrapExport}(MDXContent)`
    }

    return `${moduleBase}
export default ${fnPostMdxTypeProp}`
  }

  // Recursively walk through children
  if (node.children) {
    children = node.children
      .map(childNode => {
        const childOptions = Object.assign({}, options, {
          // Tell all children inside <pre> tags to preserve newlines as text nodes
          preserveNewlines: preserveNewlines || node.tagName === 'pre'
        })
        return toJSX(childNode, node, childOptions)
      })
      .join('')
  }

  if (node.type === 'element') {
    let props = ''

    if (node.properties) {
      spaceSeparatedProperties.forEach(prop => {
        if (Array.isArray(node.properties[prop])) {
          node.properties[prop] = node.properties[prop].join(' ')
        }
      })

      if (Object.keys(node.properties).length > 0) {
        props = JSON.stringify(node.properties)
      }
    }

    return `<${node.tagName}${
      parentNode.tagName ? ` parentName="${parentNode.tagName}"` : ''
    }${props ? ` {...${props}}` : ''}>${children}</${node.tagName}>`
  }

  // Wraps text nodes inside template string, so that we don't run into escaping issues.
  if (node.type === 'text') {
    // Don't wrap newlines unless specifically instructed to by the flag,
    // to avoid issues like React warnings caused by text nodes in tables.
    const shouldPreserveNewlines =
      preserveNewlines || parentNode.tagName === 'p'

    if (node.value === '\n' && !shouldPreserveNewlines) {
      return node.value
    }

    return toTemplateLiteral(node.value)
  }

  if (node.type === 'comment') {
    return `{/*${node.value}*/}`
  }

  if (node.type === 'import' || node.type === 'export' || node.type === 'jsx') {
    return node.value
  }
}

function compile(options = {}) {
  this.Compiler = function (tree, file) {
    return toJSX(tree, {}, {file: file || {}, ...options})
  }
}

module.exports = compile
exports = compile
exports.toJSX = toJSX
exports.default = compile
