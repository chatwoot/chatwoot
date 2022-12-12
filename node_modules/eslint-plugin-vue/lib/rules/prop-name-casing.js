/**
 * @fileoverview Requires specific casing for the Prop name in Vue components
 * @author Yu Kimura
 */
'use strict'

const utils = require('../utils')
const casing = require('../utils/casing')
const allowedCaseOptions = ['camelCase', 'snake_case']

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

function create (context) {
  const options = context.options[0]
  const caseType = allowedCaseOptions.indexOf(options) !== -1 ? options : 'camelCase'
  const converter = casing.getConverter(caseType)

  // ----------------------------------------------------------------------
  // Public
  // ----------------------------------------------------------------------

  return utils.executeOnVue(context, (obj) => {
    const props = utils.getComponentProps(obj)
      .filter(prop => prop.key && (prop.key.type === 'Literal' || (prop.key.type === 'Identifier' && !prop.node.computed)))

    for (const item of props) {
      const propName = item.key.type === 'Literal' ? item.key.value : item.key.name
      if (typeof propName !== 'string') {
        // (boolean | null | number | RegExp) Literal
        continue
      }
      const convertedName = converter(propName)
      if (convertedName !== propName) {
        context.report({
          node: item.node,
          message: 'Prop "{{name}}" is not in {{caseType}}.',
          data: {
            name: propName,
            caseType: caseType
          }
        })
      }
    }
  })
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'enforce specific casing for the Prop name in Vue components',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/prop-name-casing.html'
    },
    fixable: null,  // null or "code" or "whitespace"
    schema: [
      {
        enum: allowedCaseOptions
      }
    ]
  },
  create
}
