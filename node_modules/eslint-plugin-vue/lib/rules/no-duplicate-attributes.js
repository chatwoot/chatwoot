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
 * Get the name of the given attribute node.
 * @param {ASTNode} attribute The attribute node to get.
 * @returns {string} The name of the attribute.
 */
function getName (attribute) {
  if (!attribute.directive) {
    return attribute.key.name
  }
  if (attribute.key.name.name === 'bind') {
    return (attribute.key.argument && attribute.key.argument.name) || null
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
      description: 'disallow duplication of attributes',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/no-duplicate-attributes.html'
    },
    fixable: null,

    schema: [
      {
        type: 'object',
        properties: {
          allowCoexistClass: {
            type: 'boolean'
          },
          allowCoexistStyle: {
            type: 'boolean'
          }
        }
      }
    ]
  },

  create (context) {
    const options = context.options[0] || {}
    const allowCoexistStyle = options.allowCoexistStyle !== false
    const allowCoexistClass = options.allowCoexistClass !== false

    const directiveNames = new Set()
    const attributeNames = new Set()

    function isDuplicate (name, isDirective) {
      if ((allowCoexistStyle && name === 'style') || (allowCoexistClass && name === 'class')) {
        return isDirective ? directiveNames.has(name) : attributeNames.has(name)
      }
      return directiveNames.has(name) || attributeNames.has(name)
    }

    return utils.defineTemplateBodyVisitor(context, {
      'VStartTag' () {
        directiveNames.clear()
        attributeNames.clear()
      },
      'VAttribute' (node) {
        const name = getName(node)
        if (name == null) {
          return
        }

        if (isDuplicate(name, node.directive)) {
          context.report({
            node,
            loc: node.loc,
            message: "Duplicate attribute '{{name}}'.",
            data: { name }
          })
        }

        if (node.directive) {
          directiveNames.add(name)
        } else {
          attributeNames.add(name)
        }
      }
    })
  }
}
