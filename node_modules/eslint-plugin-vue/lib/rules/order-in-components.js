/**
 * @fileoverview Keep order of properties in components
 * @author Michał Sajnóg
 */
'use strict'

const utils = require('../utils')
const traverseNodes = require('vue-eslint-parser').AST.traverseNodes

const defaultOrder = [
  'el',
  'name',
  'parent',
  'functional',
  ['delimiters', 'comments'],
  ['components', 'directives', 'filters'],
  'extends',
  'mixins',
  'inheritAttrs',
  'model',
  ['props', 'propsData'],
  'fetch',
  'asyncData',
  'data',
  'computed',
  'watch',
  'LIFECYCLE_HOOKS',
  'methods',
  'head',
  ['template', 'render'],
  'renderError'
]

const groups = {
  LIFECYCLE_HOOKS: [
    'beforeCreate',
    'created',
    'beforeMount',
    'mounted',
    'beforeUpdate',
    'updated',
    'activated',
    'deactivated',
    'beforeDestroy',
    'destroyed'
  ]
}

function getOrderMap (order) {
  const orderMap = new Map()

  order.forEach((property, i) => {
    if (Array.isArray(property)) {
      property.forEach(p => orderMap.set(p, i))
    } else {
      orderMap.set(property, i)
    }
  })

  return orderMap
}

function isComma (node) {
  return node.type === 'Punctuator' && node.value === ','
}

const ARITHMETIC_OPERATORS = ['+', '-', '*', '/', '%', '**']
const BITWISE_OPERATORS = ['&', '|', '^', '~', '<<', '>>', '>>>']
const COMPARISON_OPERATORS = ['==', '!=', '===', '!==', '>', '>=', '<', '<=']
const RELATIONAL_OPERATORS = ['in', 'instanceof']
const ALL_BINARY_OPERATORS = [].concat(
  ARITHMETIC_OPERATORS,
  BITWISE_OPERATORS,
  COMPARISON_OPERATORS,
  RELATIONAL_OPERATORS
)
const LOGICAL_OPERATORS = ['&&', '||']

/*
 * Result `true` if the node is sure that there are no side effects
 *
 * Currently known side effects types
 *
 * node.type === 'CallExpression'
 * node.type === 'NewExpression'
 * node.type === 'UpdateExpression'
 * node.type === 'AssignmentExpression'
 * node.type === 'TaggedTemplateExpression'
 * node.type === 'UnaryExpression' && node.operator === 'delete'
 *
 * @param  {ASTNode} node target node
 * @param  {Object} visitorKeys sourceCode.visitorKey
 * @returns {Boolean} no side effects
 */
function isNotSideEffectsNode (node, visitorKeys) {
  let result = true
  const noSideEffectsNodes = new Set()
  traverseNodes(node, {
    visitorKeys,
    enterNode (node, parent) {
      if (!result) {
        return
      }

      if (
        // parent has no side effects
        noSideEffectsNodes.has(parent) ||
        // no side effects node
        node.type === 'FunctionExpression' ||
        node.type === 'Identifier' ||
        node.type === 'Literal' ||
        // es2015
        node.type === 'ArrowFunctionExpression' ||
        node.type === 'TemplateElement'
      ) {
        noSideEffectsNodes.add(node)
      } else if (
        node.type !== 'Property' &&
        node.type !== 'ObjectExpression' &&
        node.type !== 'ArrayExpression' &&
        (node.type !== 'UnaryExpression' || !['!', '~', '+', '-', 'typeof'].includes(node.operator)) &&
        (node.type !== 'BinaryExpression' || !ALL_BINARY_OPERATORS.includes(node.operator)) &&
        (node.type !== 'LogicalExpression' || !LOGICAL_OPERATORS.includes(node.operator)) &&
        node.type !== 'MemberExpression' &&
        node.type !== 'ConditionalExpression' &&
        // es2015
        node.type !== 'SpreadElement' &&
        node.type !== 'TemplateLiteral'
      ) {
        // Can not be sure that a node has no side effects
        result = false
      }
    },
    leaveNode () {}
  })

  return result
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'enforce order of properties in components',
      category: 'recommended',
      url: 'https://eslint.vuejs.org/rules/order-in-components.html'
    },
    fixable: 'code', // null or "code" or "whitespace"
    schema: [
      {
        type: 'object',
        properties: {
          order: {
            type: 'array'
          }
        },
        additionalProperties: false
      }
    ]
  },

  create (context) {
    const options = context.options[0] || {}
    const order = options.order || defaultOrder
    const extendedOrder = order.map(property => groups[property] || property)
    const orderMap = getOrderMap(extendedOrder)
    const sourceCode = context.getSourceCode()

    function checkOrder (propertiesNodes, orderMap) {
      const properties = propertiesNodes
        .filter(property => property.type === 'Property')
        .map(property => property.key)

      properties.forEach((property, i) => {
        const propertiesAbove = properties.slice(0, i)
        const unorderedProperties = propertiesAbove
          .filter(p => orderMap.get(p.name) > orderMap.get(property.name))
          .sort((p1, p2) => orderMap.get(p1.name) > orderMap.get(p2.name) ? 1 : -1)

        const firstUnorderedProperty = unorderedProperties[0]

        if (firstUnorderedProperty) {
          const line = firstUnorderedProperty.loc.start.line
          context.report({
            node: property,
            message: `The "{{name}}" property should be above the "{{firstUnorderedPropertyName}}" property on line {{line}}.`,
            data: {
              name: property.name,
              firstUnorderedPropertyName: firstUnorderedProperty.name,
              line
            },
            fix (fixer) {
              const propertyNode = property.parent
              const firstUnorderedPropertyNode = firstUnorderedProperty.parent
              const hasSideEffectsPossibility = propertiesNodes
                .slice(
                  propertiesNodes.indexOf(firstUnorderedPropertyNode),
                  propertiesNodes.indexOf(propertyNode) + 1
                )
                .some((property) => !isNotSideEffectsNode(property, sourceCode.visitorKeys))
              if (hasSideEffectsPossibility) {
                return undefined
              }
              const afterComma = sourceCode.getTokenAfter(propertyNode)
              const hasAfterComma = isComma(afterComma)

              const beforeComma = sourceCode.getTokenBefore(propertyNode)
              const codeStart = beforeComma.range[1] // to include comments
              const codeEnd = hasAfterComma ? afterComma.range[1] : propertyNode.range[1]

              const propertyCode = sourceCode.text.slice(codeStart, codeEnd) + (hasAfterComma ? '' : ',')
              const insertTarget = sourceCode.getTokenBefore(firstUnorderedPropertyNode)

              const removeStart = hasAfterComma ? codeStart : beforeComma.range[0]

              return [
                fixer.removeRange([removeStart, codeEnd]),
                fixer.insertTextAfter(insertTarget, propertyCode)
              ]
            }
          })
        }
      })
    }

    return utils.executeOnVue(context, (obj) => {
      checkOrder(obj.properties, orderMap)
    })
  }
}
