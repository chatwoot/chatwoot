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
// Helpers
// ------------------------------------------------------------------------------

const VALID_MODIFIERS = new Set(['lazy', 'number', 'trim'])

/**
 * Check whether the given node is valid or not.
 * @param {ASTNode} node The element node to check.
 * @returns {boolean} `true` if the node is valid.
 */
function isValidElement (node) {
  const name = node.name
  return (
    name === 'input' ||
    name === 'select' ||
    name === 'textarea' ||
    (
      name !== 'keep-alive' &&
      name !== 'slot' &&
      name !== 'transition' &&
      name !== 'transition-group' &&
      utils.isCustomComponent(node)
    )
  )
}

/**
 * Check whether the given node can be LHS.
 * @param {ASTNode} node The node to check.
 * @returns {boolean} `true` if the node can be LHS.
 */
function isLhs (node) {
  return node != null && (
    node.type === 'Identifier' ||
    node.type === 'MemberExpression'
  )
}

/**
 * Get the variable by names.
 * @param {string} name The variable name to find.
 * @param {ASTNode} leafNode The node to look up.
 * @returns {Variable|null} The found variable or null.
 */
function getVariable (name, leafNode) {
  let node = leafNode

  while (node != null) {
    const variables = node.variables
    const variable = variables && variables.find(v => v.id.name === name)

    if (variable != null) {
      return variable
    }

    node = node.parent
  }

  return null
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce valid `v-model` directives',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/valid-v-model.html'
    },
    fixable: null,
    schema: []
  },

  create (context) {
    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='model']" (node) {
        const element = node.parent.parent
        const name = element.name

        if (!isValidElement(element)) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-model' directives aren't supported on <{{name}}> elements.",
            data: { name }
          })
        }

        if (name === 'input' && utils.hasAttribute(element, 'type', 'file')) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-model' directives don't support 'file' input type."
          })
        }

        if (node.key.argument) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-model' directives require no argument."
          })
        }

        for (const modifier of node.key.modifiers) {
          if (!VALID_MODIFIERS.has(modifier.name)) {
            context.report({
              node,
              loc: node.loc,
              message: "'v-model' directives don't support the modifier '{{name}}'.",
              data: { name: modifier.name }
            })
          }
        }
        if (!utils.hasAttributeValue(node)) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-model' directives require that attribute value."
          })
        }
        if (node.value) {
          if (!isLhs(node.value.expression)) {
            context.report({
              node,
              loc: node.loc,
              message: "'v-model' directives require the attribute value which is valid as LHS."
            })
          }

          for (const reference of node.value.references) {
            const id = reference.id
            if (id.parent.type !== 'VExpressionContainer') {
              continue
            }

            const variable = getVariable(id.name, element)
            if (variable != null) {
              context.report({
                node,
                loc: node.loc,
                message: "'v-model' directives cannot update the iteration variable '{{varName}}' itself.",
                data: { varName: id.name }
              })
            }
          }
        }
      }
    })
  }
}
