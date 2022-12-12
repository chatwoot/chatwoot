/**
 * @fileoverview Prop definitions should be detailed
 * @author Armano
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
      description: 'require type definitions in props',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/require-prop-types.html'
    },
    fixable: null, // or "code" or "whitespace"
    schema: [
      // fill in your schema
    ]
  },

  create (context) {
    // ----------------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------------

    function objectHasType (node) {
      const typeProperty = node.properties
        .find(p =>
          utils.getStaticPropertyName(p.key) === 'type' &&
          (
            p.value.type !== 'ArrayExpression' ||
            p.value.elements.length > 0
          )
        )
      const validatorProperty = node.properties
        .find(p => utils.getStaticPropertyName(p.key) === 'validator')
      return Boolean(typeProperty || validatorProperty)
    }

    function checkProperty (key, value, node) {
      let hasType = true

      if (!value) {
        hasType = false
      } else if (value.type === 'ObjectExpression') { // foo: {
        hasType = objectHasType(value)
      } else if (value.type === 'ArrayExpression') { // foo: [
        hasType = value.elements.length > 0
      } else if (value.type === 'FunctionExpression' || value.type === 'ArrowFunctionExpression') {
        hasType = false
      }
      if (!hasType) {
        context.report({
          node,
          message: 'Prop "{{name}}" should define at least its type.',
          data: {
            name: utils.getStaticPropertyName(key || node) || 'Unknown prop'
          }
        })
      }
    }

    // ----------------------------------------------------------------------
    // Public
    // ----------------------------------------------------------------------

    return utils.executeOnVue(context, (obj) => {
      const props = utils.getComponentProps(obj)

      for (const prop of props) {
        checkProperty(prop.key, prop.value, prop.node)
      }
    })
  }
}
