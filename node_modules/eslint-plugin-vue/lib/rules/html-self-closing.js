/**
 * @author Toru Nagashima
 * @copyright 2016 Toru Nagashima. All rights reserved.
 * See LICENSE file in root directory for full license.
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------------------

/**
 * These strings wil be displayed in error messages.
 */
const ELEMENT_TYPE = Object.freeze({
  NORMAL: 'HTML elements',
  VOID: 'HTML void elements',
  COMPONENT: 'Vue.js custom components',
  SVG: 'SVG elements',
  MATH: 'MathML elements'
})

/**
 * Normalize the given options.
 * @param {Object|undefined} options The raw options object.
 * @returns {Object} Normalized options.
 */
function parseOptions (options) {
  return {
    [ELEMENT_TYPE.NORMAL]: (options && options.html && options.html.normal) || 'always',
    [ELEMENT_TYPE.VOID]: (options && options.html && options.html.void) || 'never',
    [ELEMENT_TYPE.COMPONENT]: (options && options.html && options.html.component) || 'always',
    [ELEMENT_TYPE.SVG]: (options && options.svg) || 'always',
    [ELEMENT_TYPE.MATH]: (options && options.math) || 'always'
  }
}

/**
 * Get the elementType of the given element.
 * @param {VElement} node The element node to get.
 * @returns {string} The elementType of the element.
 */
function getElementType (node) {
  if (utils.isCustomComponent(node)) {
    return ELEMENT_TYPE.COMPONENT
  }
  if (utils.isHtmlElementNode(node)) {
    if (utils.isHtmlVoidElementName(node.name)) {
      return ELEMENT_TYPE.VOID
    }
    return ELEMENT_TYPE.NORMAL
  }
  if (utils.isSvgElementNode(node)) {
    return ELEMENT_TYPE.SVG
  }
  if (utils.isMathMLElementNode(node)) {
    return ELEMENT_TYPE.MATH
  }
  return 'unknown elements'
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
  const end = (node.endTag != null) ? node.endTag.range[0] : node.range[1]

  return sourceCode.text.slice(start, end).trim() === ''
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'enforce self-closing style',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/html-self-closing.html'
    },
    fixable: 'code',
    schema: {
      definitions: {
        optionValue: {
          enum: ['always', 'never', 'any']
        }
      },
      type: 'array',
      items: [{
        type: 'object',
        properties: {
          html: {
            type: 'object',
            properties: {
              normal: { $ref: '#/definitions/optionValue' },
              void: { $ref: '#/definitions/optionValue' },
              component: { $ref: '#/definitions/optionValue' }
            },
            additionalProperties: false
          },
          svg: { $ref: '#/definitions/optionValue' },
          math: { $ref: '#/definitions/optionValue' }
        },
        additionalProperties: false
      }],
      maxItems: 1
    }
  },

  create (context) {
    const sourceCode = context.getSourceCode()
    const options = parseOptions(context.options[0])
    let hasInvalidEOF = false

    return utils.defineTemplateBodyVisitor(context, {
      'VElement' (node) {
        if (hasInvalidEOF) {
          return
        }

        const elementType = getElementType(node)
        const mode = options[elementType]

        if (mode === 'always' && !node.startTag.selfClosing && isEmpty(node, sourceCode)) {
          context.report({
            node,
            loc: node.loc,
            message: 'Require self-closing on {{elementType}} (<{{name}}>).',
            data: { elementType, name: node.rawName },
            fix: (fixer) => {
              const tokens = context.parserServices.getTemplateBodyTokenStore()
              const close = tokens.getLastToken(node.startTag)
              if (close.type !== 'HTMLTagClose') {
                return null
              }
              return fixer.replaceTextRange([close.range[0], node.range[1]], '/>')
            }
          })
        }

        if (mode === 'never' && node.startTag.selfClosing) {
          context.report({
            node,
            loc: node.loc,
            message: 'Disallow self-closing on {{elementType}} (<{{name}}/>).',
            data: { elementType, name: node.rawName },
            fix: (fixer) => {
              const tokens = context.parserServices.getTemplateBodyTokenStore()
              const close = tokens.getLastToken(node.startTag)
              if (close.type !== 'HTMLSelfClosingTagClose') {
                return null
              }
              if (elementType === ELEMENT_TYPE.VOID) {
                return fixer.replaceText(close, '>')
              }
              // If only `close` is targeted for replacement, it conflicts with `component-name-in-template-casing`,
              // so replace the entire element.
              // return fixer.replaceText(close, `></${node.rawName}>`)
              const elementPart = sourceCode.text.slice(node.range[0], close.range[0])
              return fixer.replaceText(node, elementPart + `></${node.rawName}>`)
            }
          })
        }
      }
    }, {
      Program (node) {
        hasInvalidEOF = utils.hasInvalidEOF(node)
      }
    })
  }
}
