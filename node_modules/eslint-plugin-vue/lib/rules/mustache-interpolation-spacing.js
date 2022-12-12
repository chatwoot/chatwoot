/**
 * @fileoverview enforce unified spacing in mustache interpolations.
 * @author Armano
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
      description: 'enforce unified spacing in mustache interpolations',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/mustache-interpolation-spacing.html'
    },
    fixable: 'whitespace',
    schema: [
      {
        enum: ['always', 'never']
      }
    ]
  },

  create (context) {
    const options = context.options[0] || 'always'
    const template =
      context.parserServices.getTemplateBodyTokenStore &&
      context.parserServices.getTemplateBodyTokenStore()

    // ----------------------------------------------------------------------
    // Public
    // ----------------------------------------------------------------------

    return utils.defineTemplateBodyVisitor(context, {
      'VExpressionContainer[expression!=null]' (node) {
        const openBrace = template.getFirstToken(node)
        const closeBrace = template.getLastToken(node)

        if (
          !openBrace ||
          !closeBrace ||
          openBrace.type !== 'VExpressionStart' ||
          closeBrace.type !== 'VExpressionEnd'
        ) {
          return
        }

        const firstToken = template.getTokenAfter(openBrace, { includeComments: true })
        const lastToken = template.getTokenBefore(closeBrace, { includeComments: true })

        if (options === 'always') {
          if (openBrace.range[1] === firstToken.range[0]) {
            context.report({
              node: openBrace,
              message: "Expected 1 space after '{{', but not found.",
              fix: (fixer) => fixer.insertTextAfter(openBrace, ' ')
            })
          }
          if (closeBrace.range[0] === lastToken.range[1]) {
            context.report({
              node: closeBrace,
              message: "Expected 1 space before '}}', but not found.",
              fix: (fixer) => fixer.insertTextBefore(closeBrace, ' ')
            })
          }
        } else {
          if (openBrace.range[1] !== firstToken.range[0]) {
            context.report({
              loc: {
                start: openBrace.loc.start,
                end: firstToken.loc.start
              },
              message: "Expected no space after '{{', but found.",
              fix: (fixer) => fixer.removeRange([openBrace.range[1], firstToken.range[0]])
            })
          }
          if (closeBrace.range[0] !== lastToken.range[1]) {
            context.report({
              loc: {
                start: lastToken.loc.end,
                end: closeBrace.loc.end
              },
              message: "Expected no space before '}}', but found.",
              fix: (fixer) => fixer.removeRange([lastToken.range[1], closeBrace.range[0]])
            })
          }
        }
      }
    })
  }
}
