/**
 * @author Yosuke Ota
 *
 * issue        https://github.com/vuejs/eslint-plugin-vue/issues/403
 * Style guide: https://vuejs.org/v2/style-guide/#Avoid-v-if-with-v-for-essential
 *
 * I implemented it with reference to `no-confusing-v-for-v-if`
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
 * Check whether the given `v-if` node is using the variable which is defined by the `v-for` directive.
 * @param {ASTNode} vIf The `v-if` attribute node to check.
 * @returns {boolean} `true` if the `v-if` is using the variable which is defined by the `v-for` directive.
 */
function isUsingIterationVar (vIf) {
  return !!getVForUsingIterationVar(vIf)
}

function getVForUsingIterationVar (vIf) {
  const element = vIf.parent.parent
  for (var i = 0; i < vIf.value.references.length; i++) {
    const reference = vIf.value.references[i]

    const targetVFor = element.variables.find(variable =>
      variable.id.name === reference.id.name &&
      variable.kind === 'v-for'
    )
    if (targetVFor) {
      return targetVFor
    }
  }
  return undefined
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow use v-if on the same element as v-for',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/no-use-v-if-with-v-for.html'
    },
    fixable: null,
    schema: [{
      type: 'object',
      properties: {
        allowUsingIterationVar: {
          type: 'boolean'
        }
      }
    }]
  },

  create (context) {
    const options = context.options[0] || {}
    const allowUsingIterationVar = options.allowUsingIterationVar === true // default false
    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='if']" (node) {
        const element = node.parent.parent

        if (utils.hasDirective(element, 'for')) {
          if (isUsingIterationVar(node)) {
            if (!allowUsingIterationVar) {
              const vForVar = getVForUsingIterationVar(node)

              let targetVForExpr = vForVar.id.parent
              while (targetVForExpr.type !== 'VForExpression') {
                targetVForExpr = targetVForExpr.parent
              }
              const iteratorNode = targetVForExpr.right
              context.report({
                node,
                loc: node.loc,
                message: "The '{{iteratorName}}' {{kind}} inside 'v-for' directive should be replaced with a computed property that returns filtered array instead. You should not mix 'v-for' with 'v-if'.",
                data: {
                  iteratorName: iteratorNode.type === 'Identifier' ? iteratorNode.name : context.getSourceCode().getText(iteratorNode),
                  kind: iteratorNode.type === 'Identifier' ? 'variable' : 'expression'
                }
              })
            }
          } else {
            context.report({
              node,
              loc: node.loc,
              message: "This 'v-if' should be moved to the wrapper element."
            })
          }
        }
      }
    })
  }
}
