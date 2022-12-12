/**
 * @fileoverview This rule warns about the usage of extra whitespaces between attributes
 * @author Armano
 */
'use strict'

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

const isProperty = (context, node) => {
  const sourceCode = context.getSourceCode()
  return node.type === 'Punctuator' && sourceCode.getText(node) === ':'
}

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'disallow multiple spaces',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/no-multi-spaces.html'
    },
    fixable: 'whitespace', // or "code" or "whitespace"
    schema: [{
      type: 'object',
      properties: {
        ignoreProperties: {
          type: 'boolean'
        }
      },
      additionalProperties: false
    }]
  },

  /**
   * @param {RuleContext} context - The rule context.
   * @returns {Object} AST event handlers.
   */
  create (context) {
    const options = context.options[0] || {}
    const ignoreProperties = options.ignoreProperties === true

    return {
      Program (node) {
        if (context.parserServices.getTemplateBodyTokenStore == null) {
          context.report({
            loc: { line: 1, column: 0 },
            message: 'Use the latest vue-eslint-parser. See also https://eslint.vuejs.org/user-guide/#what-is-the-use-the-latest-vue-eslint-parser-error.'
          })
          return
        }
        if (!node.templateBody) {
          return
        }
        const sourceCode = context.getSourceCode()
        const tokenStore = context.parserServices.getTemplateBodyTokenStore()
        const tokens = tokenStore.getTokens(node.templateBody, { includeComments: true })

        let prevToken = tokens.shift()
        for (const token of tokens) {
          const spaces = token.range[0] - prevToken.range[1]
          const shouldIgnore = ignoreProperties && (
            isProperty(context, token) || isProperty(context, prevToken)
          )
          if (spaces > 1 && token.loc.start.line === prevToken.loc.start.line && !shouldIgnore) {
            context.report({
              node: token,
              loc: {
                start: prevToken.loc.end,
                end: token.loc.start
              },
              message: "Multiple spaces found before '{{displayValue}}'.",
              fix: (fixer) => fixer.replaceTextRange([prevToken.range[1], token.range[0]], ' '),
              data: {
                displayValue: sourceCode.getText(token)
              }
            })
          }
          prevToken = token
        }
      }
    }
  }
}
