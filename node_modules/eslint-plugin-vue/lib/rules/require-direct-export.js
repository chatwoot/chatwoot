/**
 * @fileoverview require the component to be directly exported
 * @author Hiroki Osame <hiroki.osame@gmail.com>
 */
'use strict'

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require the component to be directly exported',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/require-direct-export.html'
    },
    fixable: null,  // or "code" or "whitespace"
    schema: []
  },

  create (context) {
    const filePath = context.getFilename()

    return {
      'ExportDefaultDeclaration:exit' (node) {
        if (!utils.isVueFile(filePath)) return

        const isObjectExpression = (
          node.type === 'ExportDefaultDeclaration' &&
          node.declaration.type === 'ObjectExpression'
        )

        if (!isObjectExpression) {
          context.report({
            node,
            message: `Expected the component literal to be directly exported.`
          })
        }
      }
    }
  }
}
