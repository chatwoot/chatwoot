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

/**
 * Check whether the given attribute is using the variables which are defined by `v-for` directives.
 * @param {ASTNode} vFor The attribute node of `v-for` to check.
 * @param {ASTNode} vBindKey The attribute node of `v-bind:key` to check.
 * @returns {boolean} `true` if the node is using the variables which are defined by `v-for` directives.
 */
function isUsingIterationVar (vFor, vBindKey) {
  if (vBindKey.value == null) {
    return false
  }
  const references = vBindKey.value.references
  const variables = vFor.parent.parent.variables
  return references.some(reference =>
    variables.some(variable =>
      variable.id.name === reference.id.name &&
            variable.kind === 'v-for'
    )
  )
}

/**
 * Check the child element in tempalte v-for about `v-bind:key` attributes.
 * @param {RuleContext} context The rule context to report.
 * @param {ASTNode} vFor The attribute node of `v-for` to check.
 * @param {ASTNode} child The child node to check.
 */
function checkChildKey (context, vFor, child) {
  const childFor = utils.getDirective(child, 'for')
  // if child has v-for, check if parent iterator is used in v-for
  if (childFor != null) {
    const childForRefs = childFor.value.references
    const variables = vFor.parent.parent.variables
    const usedInFor = childForRefs.some(cref =>
      variables.some(variable =>
        cref.id.name === variable.id.name &&
        variable.kind === 'v-for'
      )
    )
    // if parent iterator is used, skip other checks
    // iterator usage will be checked later by child v-for
    if (usedInFor) {
      return
    }
  }
  // otherwise, check if parent iterator is directly used in child's key
  checkKey(context, vFor, child)
}

/**
 * Check the given element about `v-bind:key` attributes.
 * @param {RuleContext} context The rule context to report.
 * @param {ASTNode} vFor The attribute node of `v-for` to check.
 * @param {ASTNode} element The element node to check.
 */
function checkKey (context, vFor, element) {
  if (element.name === 'template') {
    for (const child of element.children) {
      if (child.type === 'VElement') {
        checkChildKey(context, vFor, child)
      }
    }
    return
  }

  const vBindKey = utils.getDirective(element, 'bind', 'key')

  if (utils.isCustomComponent(element) && vBindKey == null) {
    context.report({
      node: element.startTag,
      loc: element.startTag.loc,
      message: "Custom elements in iteration require 'v-bind:key' directives."
    })
  }
  if (vBindKey != null && !isUsingIterationVar(vFor, vBindKey)) {
    context.report({
      node: vBindKey,
      loc: vBindKey.loc,
      message: "Expected 'v-bind:key' directive to use the variables which are defined by the 'v-for' directive."
    })
  }
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce valid `v-for` directives',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/valid-v-for.html'
    },
    fixable: null,
    schema: []
  },

  create (context) {
    const sourceCode = context.getSourceCode()

    return utils.defineTemplateBodyVisitor(context, {
      "VAttribute[directive=true][key.name.name='for']" (node) {
        const element = node.parent.parent

        checkKey(context, node, element)

        if (node.key.argument) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-for' directives require no argument."
          })
        }
        if (node.key.modifiers.length > 0) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-for' directives require no modifier."
          })
        }
        if (!utils.hasAttributeValue(node)) {
          context.report({
            node,
            loc: node.loc,
            message: "'v-for' directives require that attribute value."
          })
          return
        }

        const expr = node.value.expression
        if (expr == null) {
          return
        }
        if (expr.type !== 'VForExpression') {
          context.report({
            node: node.value,
            loc: node.value.loc,
            message: "'v-for' directives require the special syntax '<alias> in <expression>'."
          })
          return
        }

        const lhs = expr.left
        const value = lhs[0]
        const key = lhs[1]
        const index = lhs[2]

        if (value === null) {
          context.report({
            node: value || expr,
            loc: value && value.loc,
            message: "Invalid alias ''."
          })
        }
        if (key !== undefined && (!key || key.type !== 'Identifier')) {
          context.report({
            node: key || expr,
            loc: key && key.loc,
            message: "Invalid alias '{{text}}'.",
            data: { text: key ? sourceCode.getText(key) : '' }
          })
        }
        if (index !== undefined && (!index || index.type !== 'Identifier')) {
          context.report({
            node: index || expr,
            loc: index && index.loc,
            message: "Invalid alias '{{text}}'.",
            data: { text: index ? sourceCode.getText(index) : '' }
          })
        }
      }
    })
  }
}
