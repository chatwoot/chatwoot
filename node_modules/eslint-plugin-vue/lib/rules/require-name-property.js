/**
 * @fileoverview Require a name property in Vue components
 * @author LukeeeeBennett
 */
'use strict'

const utils = require('../utils')

function isNameProperty (node) {
  return node.type === 'Property' &&
    node.key.name === 'name' &&
    !node.computed
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require a name property in Vue components',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/require-name-property.html'
    },
    fixable: null,
    schema: []
  },

  create (context) {
    return utils.executeOnVue(context, component => {
      if (component.properties.some(isNameProperty)) return

      context.report({
        node: component,
        message: 'Required name property is not set.'
      })
    })
  }
}
