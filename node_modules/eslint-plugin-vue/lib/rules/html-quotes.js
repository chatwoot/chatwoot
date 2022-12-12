/**
 * @author Toru Nagashima
 * @copyright 2017 Toru Nagashima. All rights reserved.
 * See LICENSE file in root directory for full license.
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'enforce quotes style of HTML attributes',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/html-quotes.html'
    },
    fixable: 'code',
    schema: [
      { enum: ['double', 'single'] },
      {
        type: 'object',
        properties: {
          avoidEscape: {
            type: 'boolean'
          }
        },
        additionalProperties: false
      }
    ]
  },

  create (context) {
    const sourceCode = context.getSourceCode()
    const double = context.options[0] !== 'single'
    const avoidEscape = context.options[1] && context.options[1].avoidEscape === true
    const quoteChar = double ? '"' : "'"
    const quoteName = double ? 'double quotes' : 'single quotes'
    let hasInvalidEOF

    return utils.defineTemplateBodyVisitor(context, {
      'VAttribute[value!=null]' (node) {
        if (hasInvalidEOF) {
          return
        }

        const text = sourceCode.getText(node.value)
        const firstChar = text[0]

        if (firstChar !== quoteChar) {
          const quoted = (firstChar === "'" || firstChar === '"')
          if (avoidEscape && quoted) {
            const contentText = text.slice(1, -1)
            if (contentText.includes(quoteChar)) {
              return
            }
          }

          context.report({
            node: node.value,
            loc: node.value.loc,
            message: 'Expected to be enclosed by {{kind}}.',
            data: { kind: quoteName },
            fix (fixer) {
              const contentText = quoted ? text.slice(1, -1) : text

              const fixToDouble = avoidEscape && !quoted && contentText.includes(quoteChar)
                ? (
                  double
                    ? contentText.includes("'")
                    : !contentText.includes('"')
                )
                : double

              const quotePattern = fixToDouble ? /"/g : /'/g
              const quoteEscaped = fixToDouble ? '&quot;' : '&apos;'
              const fixQuoteChar = fixToDouble ? '"' : "'"

              const replacement = fixQuoteChar + contentText.replace(quotePattern, quoteEscaped) + fixQuoteChar
              return fixer.replaceText(node.value, replacement)
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
