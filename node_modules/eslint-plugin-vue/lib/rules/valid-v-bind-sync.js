/**
 * @fileoverview enforce valid `.sync` modifier on `v-bind` directives
 * @author Yosuke Ota
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
 * Check whether the given node is valid or not.
 * @param {ASTNode} node The element node to check.
 * @returns {boolean} `true` if the node is valid.
 */
function isValidElement (node) {
  if (
    (!utils.isHtmlElementNode(node) && !utils.isSvgElementNode(node)) ||
    utils.isHtmlWellKnownElementName(node.rawName) ||
    utils.isSvgWellKnownElementName(node.rawName)
  ) {
    // non Vue-component
    return false
  }
  return true
}

/**
 * Check whether the given node can be LHS.
 * @param {ASTNode} node The node to check.
 * @returns {boolean} `true` if the node can be LHS.
 */
function isLhs (node) {
  return Boolean(node) && (
    node.type === 'Identifier' ||
    node.type === 'MemberExpression'
  )
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce valid `.sync` modifier on `v-bind` directives',
      category: undefined,
      // TODO Change with major version.
      // category: 'essential',
      url: 'https://eslint.vuejs.org/rules/valid-v-bind-sync.html'
    },
    fixable: null,
    schema: [],
    messages: {
      unexpectedInvalidElement: "'.sync' modifiers aren't supported on <{{name}}> non Vue-components.",
      unexpectedNonLhsExpression: "'.sync' modifiers require the attribute value which is valid as LHS.",
      unexpectedUpdateIterationVariable: "'.sync' modifiers cannot update the iteration variable '{{varName}}' itself."
    }
  },

  create (context) {
    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='bind']" (node) {
        if (!node.key.modifiers.map(mod => mod.name).includes('sync')) {
          return
        }
        const element = node.parent.parent
        const name = element.name

        if (!isValidElement(element)) {
          context.report({
            node,
            loc: node.loc,
            messageId: 'unexpectedInvalidElement',
            data: { name }
          })
        }

        if (node.value) {
          if (!isLhs(node.value.expression)) {
            context.report({
              node,
              loc: node.loc,
              messageId: 'unexpectedNonLhsExpression'
            })
          }

          for (const reference of node.value.references) {
            const id = reference.id
            if (id.parent.type !== 'VExpressionContainer') {
              continue
            }
            const variable = reference.variable
            if (variable) {
              context.report({
                node,
                loc: node.loc,
                messageId: 'unexpectedUpdateIterationVariable',
                data: { varName: id.name }
              })
            }
          }
        }
      }
    })
  }
}
