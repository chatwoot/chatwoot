/**
 * @fileoverview enforce ordering of attributes
 * @author Erin Depew
 */
'use strict'
const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------
const ATTRS = {
  DEFINITION: 'DEFINITION',
  LIST_RENDERING: 'LIST_RENDERING',
  CONDITIONALS: 'CONDITIONALS',
  RENDER_MODIFIERS: 'RENDER_MODIFIERS',
  GLOBAL: 'GLOBAL',
  UNIQUE: 'UNIQUE',
  TWO_WAY_BINDING: 'TWO_WAY_BINDING',
  OTHER_DIRECTIVES: 'OTHER_DIRECTIVES',
  OTHER_ATTR: 'OTHER_ATTR',
  EVENTS: 'EVENTS',
  CONTENT: 'CONTENT'
}

function getAttributeName (attribute, sourceCode) {
  const isBind = attribute.directive && attribute.key.name.name === 'bind'
  return isBind
    ? (attribute.key.argument ? sourceCode.getText(attribute.key.argument) : '')
    : (attribute.directive ? getDirectiveKeyName(attribute.key, sourceCode) : attribute.key.name)
}

function getDirectiveKeyName (directiveKey, sourceCode) {
  let text = 'v-' + directiveKey.name.name
  if (directiveKey.argument) {
    text += ':' + sourceCode.getText(directiveKey.argument)
  }
  for (const modifier of directiveKey.modifiers) {
    text += '.' + modifier.name
  }
  return text
}

function getAttributeType (attribute, sourceCode) {
  const isBind = attribute.directive && attribute.key.name.name === 'bind'
  const name = isBind
    ? (attribute.key.argument ? sourceCode.getText(attribute.key.argument) : '')
    : (attribute.directive ? attribute.key.name.name : attribute.key.name)

  if (attribute.directive && !isBind) {
    if (name === 'for') {
      return ATTRS.LIST_RENDERING
    } else if (name === 'if' || name === 'else-if' || name === 'else' || name === 'show' || name === 'cloak') {
      return ATTRS.CONDITIONALS
    } else if (name === 'pre' || name === 'once') {
      return ATTRS.RENDER_MODIFIERS
    } else if (name === 'model') {
      return ATTRS.TWO_WAY_BINDING
    } else if (name === 'on') {
      return ATTRS.EVENTS
    } else if (name === 'html' || name === 'text') {
      return ATTRS.CONTENT
    } else if (name === 'slot') {
      return ATTRS.UNIQUE
    } else {
      return ATTRS.OTHER_DIRECTIVES
    }
  } else {
    if (name === 'is') {
      return ATTRS.DEFINITION
    } else if (name === 'id') {
      return ATTRS.GLOBAL
    } else if (name === 'ref' || name === 'key' || name === 'slot' || name === 'slot-scope') {
      return ATTRS.UNIQUE
    } else {
      return ATTRS.OTHER_ATTR
    }
  }
}

function getPosition (attribute, attributePosition, sourceCode) {
  const attributeType = getAttributeType(attribute, sourceCode)
  return attributePosition.hasOwnProperty(attributeType) ? attributePosition[attributeType] : -1
}

function isAlphabetical (prevNode, currNode, sourceCode) {
  const isSameType = getAttributeType(prevNode, sourceCode) === getAttributeType(currNode, sourceCode)
  if (isSameType) {
    const prevName = getAttributeName(prevNode, sourceCode)
    const currName = getAttributeName(currNode, sourceCode)
    if (prevName === currName) {
      const prevIsBind = Boolean(prevNode.directive && prevNode.key.name.name === 'bind')
      const currIsBind = Boolean(currNode.directive && currNode.key.name.name === 'bind')
      return prevIsBind <= currIsBind
    }
    return prevName < currName
  }
  return true
}

function create (context) {
  const sourceCode = context.getSourceCode()
  let attributeOrder = [ATTRS.DEFINITION, ATTRS.LIST_RENDERING, ATTRS.CONDITIONALS, ATTRS.RENDER_MODIFIERS, ATTRS.GLOBAL, ATTRS.UNIQUE, ATTRS.TWO_WAY_BINDING, ATTRS.OTHER_DIRECTIVES, ATTRS.OTHER_ATTR, ATTRS.EVENTS, ATTRS.CONTENT]
  if (context.options[0] && context.options[0].order) {
    attributeOrder = context.options[0].order
  }
  const attributePosition = {}
  attributeOrder.forEach((item, i) => {
    if (item instanceof Array) {
      item.forEach((attr) => {
        attributePosition[attr] = i
      })
    } else attributePosition[item] = i
  })
  let currentPosition
  let previousNode

  function reportIssue (node, previousNode) {
    const currentNode = sourceCode.getText(node.key)
    const prevNode = sourceCode.getText(previousNode.key)
    context.report({
      node: node.key,
      loc: node.loc,
      message: `Attribute "${currentNode}" should go before "${prevNode}".`,
      data: {
        currentNode
      },

      fix (fixer) {
        const attributes = node.parent.attributes
        const shiftAttrs = attributes.slice(attributes.indexOf(previousNode), attributes.indexOf(node) + 1)

        return shiftAttrs.map((attr, i) => {
          const text = attr === previousNode ? sourceCode.getText(node) : sourceCode.getText(shiftAttrs[i - 1])
          return fixer.replaceText(attr, text)
        })
      }
    })
  }

  return utils.defineTemplateBodyVisitor(context, {
    'VStartTag' () {
      currentPosition = -1
      previousNode = null
    },
    'VAttribute' (node) {
      let inAlphaOrder = true
      if (currentPosition !== -1 && (context.options[0] && context.options[0].alphabetical)) {
        inAlphaOrder = isAlphabetical(previousNode, node, sourceCode)
      }
      if ((currentPosition === -1) || ((currentPosition <= getPosition(node, attributePosition, sourceCode)) && inAlphaOrder)) {
        currentPosition = getPosition(node, attributePosition, sourceCode)
        previousNode = node
      } else {
        reportIssue(node, previousNode)
      }
    }
  })
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'enforce order of attributes',
      category: 'recommended',
      url: 'https://eslint.vuejs.org/rules/attributes-order.html'
    },
    fixable: 'code',
    schema: {
      type: 'array',
      properties: {
        order: {
          items: {
            type: 'string'
          },
          maxItems: 10,
          minItems: 10
        }
      }
    }
  },
  create
}
