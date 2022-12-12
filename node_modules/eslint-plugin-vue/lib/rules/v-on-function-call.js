/**
 * @author Niklas Higi
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
    type: 'suggestion',
    docs: {
      description: 'enforce or forbid parentheses after method calls without arguments in `v-on` directives',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/v-on-function-call.html'
    },
    fixable: 'code',
    schema: [
      { enum: ['always', 'never'] }
    ]
  },

  create (context) {
    const always = context.options[0] === 'always'

    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='on'][key.argument!=null] > VExpressionContainer > Identifier" (node) {
        if (!always) return
        context.report({
          node,
          loc: node.loc,
          message: "Method calls inside of 'v-on' directives must have parentheses."
        })
      },

      "VAttribute[directive=true][key.name.name='on'][key.argument!=null] VOnExpression > ExpressionStatement > *" (node) {
        if (!always && node.type === 'CallExpression' && node.arguments.length === 0) {
          context.report({
            node,
            loc: node.loc,
            message: "Method calls without arguments inside of 'v-on' directives must not have parentheses.",
            fix: fixer => {
              const nodeString = context.getSourceCode().getText().substring(node.range[0], node.range[1])
              // This ensures that parens are also removed if they contain whitespace
              const parensLength = nodeString.match(/\(\s*\)\s*$/)[0].length
              return fixer.removeRange([node.end - parensLength, node.end])
            }
          })
        }
      }
    })
  }
}
