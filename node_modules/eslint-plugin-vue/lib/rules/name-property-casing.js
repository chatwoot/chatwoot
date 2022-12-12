/**
 * @fileoverview Requires specific casing for the name property in Vue components
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
      description: 'enforce specific casing for the name property in Vue components',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/name-property-casing.html'
    },
    // deprecated: true, // TODO Change with major version.
    // replacedBy: ['component-definition-name-casing'], // TODO Change with major version.
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

    return utils.executeOnVue(context, (obj) => {
      const node = obj.properties
        .find(item => (
          item.type === 'Property' &&
          item.key.name === 'name' &&
          item.value.type === 'Literal'
        ))

      if (!node) return

      const value = casing.getConverter(caseType)(node.value.value)
      if (value !== node.value.value) {
        context.report({
          node: node.value,
          message: 'Property name "{{value}}" is not {{caseType}}.',
          data: {
            value: node.value.value,
            caseType: caseType
          },
          fix: fixer => fixer.replaceText(node.value, node.value.raw.replace(node.value.value, value))
        })
      }
    })
  }
}
