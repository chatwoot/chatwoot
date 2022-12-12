/**
 * @fileoverview enforce specific casing for component definition name
 * @author Armano
 */
'use strict'

const utils = require('../utils')
const casing = require('../utils/casing')
const allowedCaseOptions = ['PascalCase', 'kebab-case']

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'enforce specific casing for component definition name',
      category: undefined,
      // TODO Change with major version.
      // category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/component-definition-name-casing.html'
    },
    fixable: 'code', // or "code" or "whitespace"
    schema: [
      {
        enum: allowedCaseOptions
      }
    ]
  },

  create (context) {
    const options = context.options[0]
    const caseType = allowedCaseOptions.indexOf(options) !== -1 ? options : 'PascalCase'

    // ----------------------------------------------------------------------
    // Public
    // ----------------------------------------------------------------------

    function convertName (node) {
      let nodeValue
      let range
      if (node.type === 'TemplateLiteral') {
        const quasis = node.quasis[0]
        nodeValue = quasis.value.cooked
        range = quasis.range
      } else {
        nodeValue = node.value
        range = node.range
      }

      const value = casing.getConverter(caseType)(nodeValue)
      if (value !== nodeValue) {
        context.report({
          node: node,
          message: 'Property name "{{value}}" is not {{caseType}}.',
          data: {
            value: nodeValue,
            caseType: caseType
          },
          fix: fixer => fixer.replaceTextRange([range[0] + 1, range[1] - 1], value)
        })
      }
    }

    function canConvert (node) {
      return node.type === 'Literal' || (
        node.type === 'TemplateLiteral' &&
        node.expressions.length === 0 &&
        node.quasis.length === 1
      )
    }

    return Object.assign({},
      utils.executeOnCallVueComponent(context, (node) => {
        if (node.arguments.length === 2) {
          const argument = node.arguments[0]

          if (canConvert(argument)) {
            convertName(argument)
          }
        }
      }),
      utils.executeOnVue(context, (obj) => {
        const node = obj.properties
          .find(item => (
            item.type === 'Property' &&
            item.key.name === 'name' &&
            canConvert(item.value)
          ))

        if (!node) return
        convertName(node.value)
      })
    )
  }
}
