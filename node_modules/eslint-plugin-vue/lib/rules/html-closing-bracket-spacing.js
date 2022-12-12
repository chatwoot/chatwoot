/**
 * @author Toru Nagashima <https://github.com/mysticatea>
 */

'use strict'

// -----------------------------------------------------------------------------
// Requirements
// -----------------------------------------------------------------------------

const utils = require('../utils')

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

/**
 * Normalize options.
 * @param {{startTag?:"always"|"never",endTag?:"always"|"never",selfClosingTag?:"always"|"never"}} options The options user configured.
 * @param {TokenStore} tokens The token store of template body.
 * @returns {{startTag:"always"|"never",endTag:"always"|"never",selfClosingTag:"always"|"never"}} The normalized options.
 */
function parseOptions (options, tokens) {
  return Object.assign({
    startTag: 'never',
    endTag: 'never',
    selfClosingTag: 'always',

    detectType (node) {
      const openType = tokens.getFirstToken(node).type
      const closeType = tokens.getLastToken(node).type

      if (openType === 'HTMLEndTagOpen' && closeType === 'HTMLTagClose') {
        return this.endTag
      }
      if (openType === 'HTMLTagOpen' && closeType === 'HTMLTagClose') {
        return this.startTag
      }
      if (openType === 'HTMLTagOpen' && closeType === 'HTMLSelfClosingTagClose') {
        return this.selfClosingTag
      }
      return null
    }
  }, options)
}

// -----------------------------------------------------------------------------
// Rule Definition
// -----------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'require or disallow a space before tag\'s closing brackets',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/html-closing-bracket-spacing.html'
    },
    schema: [{
      type: 'object',
      properties: {
        startTag: { enum: ['always', 'never'] },
        endTag: { enum: ['always', 'never'] },
        selfClosingTag: { enum: ['always', 'never'] }
      },
      additionalProperties: false
    }],
    fixable: 'whitespace'
  },

  create (context) {
    const sourceCode = context.getSourceCode()
    const tokens =
      context.parserServices.getTemplateBodyTokenStore &&
      context.parserServices.getTemplateBodyTokenStore()
    const options = parseOptions(context.options[0], tokens)

    return utils.defineTemplateBodyVisitor(context, {
      'VStartTag, VEndTag' (node) {
        const type = options.detectType(node)
        const lastToken = tokens.getLastToken(node)
        const prevToken = tokens.getLastToken(node, 1)

        // Skip if EOF exists in the tag or linebreak exists before `>`.
        if (type == null || prevToken == null || prevToken.loc.end.line !== lastToken.loc.start.line) {
          return
        }

        // Check and report.
        const hasSpace = (prevToken.range[1] !== lastToken.range[0])
        if (type === 'always' && !hasSpace) {
          context.report({
            node,
            loc: lastToken.loc,
            message: "Expected a space before '{{bracket}}', but not found.",
            data: { bracket: sourceCode.getText(lastToken) },
            fix: (fixer) => fixer.insertTextBefore(lastToken, ' ')
          })
        } else if (type === 'never' && hasSpace) {
          context.report({
            node,
            loc: {
              start: prevToken.loc.end,
              end: lastToken.loc.end
            },
            message: "Expected no space before '{{bracket}}', but found.",
            data: { bracket: sourceCode.getText(lastToken) },
            fix: (fixer) => fixer.removeRange([prevToken.range[1], lastToken.range[0]])
          })
        }
      }
    })
  }
}
