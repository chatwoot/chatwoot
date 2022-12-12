/**
 * @fileoverview require prop type to be a constructor
 * @author Michał Sajnóg
 */
'use strict'

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

const message = 'The "{{name}}" property should be a constructor.'

const forbiddenTypes = [
  'Literal',
  'TemplateLiteral',
  'BinaryExpression',
  'UpdateExpression'
]

const isForbiddenType = node => forbiddenTypes.indexOf(node.type) > -1 && node.raw !== 'null'

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require prop type to be a constructor',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/require-prop-type-constructor.html'
    },
    fixable: 'code',  // or "code" or "whitespace"
    schema: []
  },

  create (context) {
    const fix = node => fixer => {
      let newText
      if (node.type === 'Literal') {
        if (typeof node.value !== 'string') {
          return undefined
        }
        newText = node.value
      } else if (
        node.type === 'TemplateLiteral' &&
        node.expressions.length === 0 &&
        node.quasis.length === 1
      ) {
        newText = node.quasis[0].value.cooked
      } else {
        return undefined
      }
      if (newText) {
        return fixer.replaceText(node, newText)
      }
    }

    const checkPropertyNode = (key, node) => {
      if (isForbiddenType(node)) {
        context.report({
          node: node,
          message,
          data: {
            name: utils.getStaticPropertyName(key)
          },
          fix: fix(node)
        })
      } else if (node.type === 'ArrayExpression') {
        node.elements
          .filter(prop => prop && isForbiddenType(prop))
          .forEach(prop => context.report({
            node: prop,
            message,
            data: {
              name: utils.getStaticPropertyName(key)
            },
            fix: fix(prop)
          }))
      }
    }

    return utils.executeOnVueComponent(context, (obj) => {
      const props = utils.getComponentProps(obj)
        .filter(prop => prop.key && prop.value)

      for (const prop of props) {
        if (isForbiddenType(prop.value) || prop.value.type === 'ArrayExpression') {
          checkPropertyNode(prop.key, prop.value)
        } else if (prop.value.type === 'ObjectExpression') {
          const typeProperty = prop.value.properties.find(property =>
            property.type === 'Property' &&
            property.key.name === 'type'
          )

          if (!typeProperty) continue

          checkPropertyNode(prop.key, typeProperty.value)
        }
      }
    })
  }
}
