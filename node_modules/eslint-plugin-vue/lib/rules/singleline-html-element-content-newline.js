/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')
const casing = require('../utils/casing')
const INLINE_ELEMENTS = require('../utils/inline-non-void-elements.json')

// ------------------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------------------

function isSinglelineElement (element) {
  return element.loc.start.line === element.endTag.loc.start.line
}

function parseOptions (options) {
  return Object.assign({
    ignores: ['pre', 'textarea'].concat(INLINE_ELEMENTS),
    ignoreWhenNoAttributes: true,
    ignoreWhenEmpty: true
  }, options)
}

/**
 * Check whether the given element is empty or not.
 * This ignores whitespaces, doesn't ignore comments.
 * @param {VElement} node The element node to check.
 * @param {SourceCode} sourceCode The source code object of the current context.
 * @returns {boolean} `true` if the element is empty.
 */
function isEmpty (node, sourceCode) {
  const start = node.startTag.range[1]
  const end = node.endTag.range[0]
  return sourceCode.text.slice(start, end).trim() === ''
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'require a line break before and after the contents of a singleline element',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/singleline-html-element-content-newline.html'
    },
    fixable: 'whitespace',
    schema: [{
      type: 'object',
      properties: {
        ignoreWhenNoAttributes: {
          type: 'boolean'
        },
        ignoreWhenEmpty: {
          type: 'boolean'
        },
        ignores: {
          type: 'array',
          items: { type: 'string' },
          uniqueItems: true,
          additionalItems: false
        }
      },
      additionalProperties: false
    }],
    messages: {
      unexpectedAfterClosingBracket: 'Expected 1 line break after opening tag (`<{{name}}>`), but no line breaks found.',
      unexpectedBeforeOpeningBracket: 'Expected 1 line break before closing tag (`</{{name}}>`), but no line breaks found.'
    }
  },

  create (context) {
    const options = parseOptions(context.options[0])
    const ignores = options.ignores
    const ignoreWhenNoAttributes = options.ignoreWhenNoAttributes
    const ignoreWhenEmpty = options.ignoreWhenEmpty
    const template = context.parserServices.getTemplateBodyTokenStore && context.parserServices.getTemplateBodyTokenStore()
    const sourceCode = context.getSourceCode()

    let inIgnoreElement

    function isIgnoredElement (node) {
      return ignores.includes(node.name) ||
        ignores.includes(casing.pascalCase(node.rawName)) ||
        ignores.includes(casing.kebabCase(node.rawName))
    }

    return utils.defineTemplateBodyVisitor(context, {
      'VElement' (node) {
        if (inIgnoreElement) {
          return
        }
        if (isIgnoredElement(node)) {
          // ignore element name
          inIgnoreElement = node
          return
        }
        if (node.startTag.selfClosing || !node.endTag) {
          // self closing
          return
        }

        if (!isSinglelineElement(node)) {
          return
        }
        if (ignoreWhenNoAttributes && node.startTag.attributes.length === 0) {
          return
        }

        const getTokenOption = { includeComments: true, filter: (token) => token.type !== 'HTMLWhitespace' }
        if (
          ignoreWhenEmpty &&
          node.children.length === 0 &&
          template.getFirstTokensBetween(node.startTag, node.endTag, getTokenOption).length === 0
        ) {
          return
        }

        const contentFirst = template.getTokenAfter(node.startTag, getTokenOption)
        const contentLast = template.getTokenBefore(node.endTag, getTokenOption)

        context.report({
          node: template.getLastToken(node.startTag),
          loc: {
            start: node.startTag.loc.end,
            end: contentFirst.loc.start
          },
          messageId: 'unexpectedAfterClosingBracket',
          data: {
            name: node.rawName
          },
          fix (fixer) {
            const range = [node.startTag.range[1], contentFirst.range[0]]
            return fixer.replaceTextRange(range, '\n')
          }
        })

        if (isEmpty(node, sourceCode)) {
          return
        }

        context.report({
          node: template.getFirstToken(node.endTag),
          loc: {
            start: contentLast.loc.end,
            end: node.endTag.loc.start
          },
          messageId: 'unexpectedBeforeOpeningBracket',
          data: {
            name: node.rawName
          },
          fix (fixer) {
            const range = [contentLast.range[1], node.endTag.range[0]]
            return fixer.replaceTextRange(range, '\n')
          }
        })
      },
      'VElement:exit' (node) {
        if (inIgnoreElement === node) {
          inIgnoreElement = null
        }
      }
    })
  }
}
