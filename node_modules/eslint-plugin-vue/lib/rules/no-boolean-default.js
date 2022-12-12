/**
 * @fileoverview Prevents boolean defaults from being set
 * @author Hiroki Osame
 */
'use strict'

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

function isBooleanProp (prop) {
  return (
    prop.type === 'Property' &&
    prop.key.type === 'Identifier' &&
    prop.key.name === 'type' &&
    prop.value.type === 'Identifier' &&
    prop.value.name === 'Boolean'
  )
}

function getBooleanProps (props) {
  return props
    .filter(prop => (
      prop.value &&
      prop.value.properties &&
      prop.value.properties.find(isBooleanProp)
    ))
}

function getDefaultNode (propDef) {
  return propDef.value.properties.find(p => {
    return (
      p.type === 'Property' &&
      p.key.type === 'Identifier' &&
      p.key.name === 'default'
    )
  })
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow boolean defaults',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/no-boolean-default.html'
    },
    fixable: 'code',
    schema: [
      {
        enum: ['default-false', 'no-default']
      }
    ]
  },

  create (context) {
    return utils.executeOnVueComponent(context, (obj) => {
      const props = utils.getComponentProps(obj)
      const booleanProps = getBooleanProps(props)

      if (!booleanProps.length) return

      const booleanType = context.options[0] || 'no-default'

      booleanProps.forEach((propDef) => {
        const defaultNode = getDefaultNode(propDef)

        switch (booleanType) {
          case 'no-default':
            if (defaultNode) {
              context.report({
                node: defaultNode,
                message: 'Boolean prop should not set a default (Vue defaults it to false).'
              })
            }
            break

          case 'default-false':
            if (
              defaultNode &&
              defaultNode.value.value !== false
            ) {
              context.report({
                node: defaultNode,
                message: 'Boolean prop should only be defaulted to false.'
              })
            }
            break
        }
      })
    })
  }
}
