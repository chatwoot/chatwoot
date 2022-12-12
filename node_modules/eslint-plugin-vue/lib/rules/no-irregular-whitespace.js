/**
 * @author Yosuke Ota
 * @fileoverview Rule to disalow whitespace that is not a tab or space, whitespace inside strings and comments are allowed
 */

'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Constants
// ------------------------------------------------------------------------------

const ALL_IRREGULARS = /[\f\v\u0085\ufeff\u00a0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u202f\u205f\u3000\u2028\u2029]/u
const IRREGULAR_WHITESPACE = /[\f\v\u0085\ufeff\u00a0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u202f\u205f\u3000]+/mgu
const IRREGULAR_LINE_TERMINATORS = /[\u2028\u2029]/mgu

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'problem',

    docs: {
      description: 'disallow irregular whitespace',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/no-irregular-whitespace.html'
    },

    schema: [
      {
        type: 'object',
        properties: {
          skipComments: {
            type: 'boolean',
            default: false
          },
          skipStrings: {
            type: 'boolean',
            default: true
          },
          skipTemplates: {
            type: 'boolean',
            default: false
          },
          skipRegExps: {
            type: 'boolean',
            default: false
          },
          skipHTMLAttributeValues: {
            type: 'boolean',
            default: false
          },
          skipHTMLTextContents: {
            type: 'boolean',
            default: false
          }
        },
        additionalProperties: false
      }
    ],
    messages: {
      disallow: 'Irregular whitespace not allowed.'
    }
  },

  create (context) {
    // Module store of error indexes that we have found
    let errorIndexes = []

    // Lookup the `skipComments` option, which defaults to `false`.
    const options = context.options[0] || {}
    const skipComments = !!options.skipComments
    const skipStrings = options.skipStrings !== false
    const skipRegExps = !!options.skipRegExps
    const skipTemplates = !!options.skipTemplates
    const skipHTMLAttributeValues = !!options.skipHTMLAttributeValues
    const skipHTMLTextContents = !!options.skipHTMLTextContents

    const sourceCode = context.getSourceCode()

    /**
     * Removes errors that occur inside a string node
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeWhitespaceError (node) {
      const [startIndex, endIndex] = node.range

      errorIndexes = errorIndexes
        .filter(errorIndex => errorIndex < startIndex || endIndex <= errorIndex)
    }

    /**
     * Checks literal nodes for errors that we are choosing to ignore and calls the relevant methods to remove the errors
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeInvalidNodeErrorsInLiteral (node) {
      const shouldCheckStrings = skipStrings && (typeof node.value === 'string')
      const shouldCheckRegExps = skipRegExps && Boolean(node.regex)

      if (shouldCheckStrings || shouldCheckRegExps) {
        // If we have irregular characters remove them from the errors list
        if (ALL_IRREGULARS.test(node.raw)) {
          removeWhitespaceError(node)
        }
      }
    }

    /**
     * Checks template string literal nodes for errors that we are choosing to ignore and calls the relevant methods to remove the errors
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeInvalidNodeErrorsInTemplateLiteral (node) {
      if (ALL_IRREGULARS.test(node.value.raw)) {
        removeWhitespaceError(node)
      }
    }

    /**
     * Checks HTML attribute value nodes for errors that we are choosing to ignore and calls the relevant methods to remove the errors
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeInvalidNodeErrorsInHTMLAttributeValue (node) {
      if (ALL_IRREGULARS.test(sourceCode.getText(node))) {
        removeWhitespaceError(node)
      }
    }

    /**
     * Checks HTML text content nodes for errors that we are choosing to ignore and calls the relevant methods to remove the errors
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeInvalidNodeErrorsInHTMLTextContent (node) {
      if (ALL_IRREGULARS.test(sourceCode.getText(node))) {
        removeWhitespaceError(node)
      }
    }

    /**
     * Checks comment nodes for errors that we are choosing to ignore and calls the relevant methods to remove the errors
     * @param {ASTNode} node to check for matching errors.
     * @returns {void}
     * @private
     */
    function removeInvalidNodeErrorsInComment (node) {
      if (ALL_IRREGULARS.test(node.value)) {
        removeWhitespaceError(node)
      }
    }

    /**
     * Checks the program source for irregular whitespaces and irregular line terminators
     * @returns {void}
     * @private
     */
    function checkForIrregularWhitespace () {
      const source = sourceCode.getText()
      let match
      while ((match = IRREGULAR_WHITESPACE.exec(source)) !== null) {
        errorIndexes.push(match.index)
      }
      while ((match = IRREGULAR_LINE_TERMINATORS.exec(source)) !== null) {
        errorIndexes.push(match.index)
      }
    }

    checkForIrregularWhitespace()

    if (!errorIndexes.length) {
      return {}
    }
    const bodyVisitor = utils.defineTemplateBodyVisitor(context,
      {
        ...(skipHTMLAttributeValues ? { 'VAttribute[directive=false] > VLiteral': removeInvalidNodeErrorsInHTMLAttributeValue } : {}),
        ...(skipHTMLTextContents ? { VText: removeInvalidNodeErrorsInHTMLTextContent } : {}),

        // inline scripts
        Literal: removeInvalidNodeErrorsInLiteral,
        ...(skipTemplates ? { TemplateElement: removeInvalidNodeErrorsInTemplateLiteral } : {})
      }
    )
    return {
      ...bodyVisitor,
      Literal: removeInvalidNodeErrorsInLiteral,
      ...(skipTemplates ? { TemplateElement: removeInvalidNodeErrorsInTemplateLiteral } : {}),
      'Program:exit' (node) {
        if (bodyVisitor['Program:exit']) {
          bodyVisitor['Program:exit'](node)
        }
        const templateBody = node.templateBody
        if (skipComments) {
          // First strip errors occurring in comment nodes.
          sourceCode.getAllComments().forEach(removeInvalidNodeErrorsInComment)
          if (templateBody) {
            templateBody.comments.forEach(removeInvalidNodeErrorsInComment)
          }
        }

        // Removes errors that occur outside script and template
        const [scriptStart, scriptEnd] = node.range
        const [templateStart, templateEnd] = templateBody ? templateBody.range : [0, 0]
        errorIndexes = errorIndexes
          .filter(errorIndex =>
            (scriptStart <= errorIndex && errorIndex < scriptEnd) ||
              (templateStart <= errorIndex && errorIndex < templateEnd)
          )

        // If we have any errors remaining report on them
        errorIndexes.forEach(errorIndex => {
          context.report({
            loc: sourceCode.getLocFromIndex(errorIndex),
            messageId: 'disallow'
          })
        })
      }
    }
  }
}
