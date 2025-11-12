/**
 * @fileoverview Prevents boolean defaults from being set
 * @author Hiroki Osame
 */
'use strict'

const utils = require('../utils')

/**
 * @typedef {import('../utils').ComponentProp} ComponentProp
 */

/**
 * @param {Property | SpreadElement} prop
 */
function isBooleanProp(prop) {
  return (
    prop.type === 'Property' &&
    prop.key.type === 'Identifier' &&
    prop.key.name === 'type' &&
    prop.value.type === 'Identifier' &&
    prop.value.name === 'Boolean'
  )
}

/**
 * @param {ObjectExpression} propDefValue
 */
function getDefaultNode(propDefValue) {
  return utils.findProperty(propDefValue, 'default')
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow boolean defaults',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-boolean-default.html'
    },
    fixable: null,
    schema: [
      {
        enum: ['default-false', 'no-default']
      }
    ],
    messages: {
      noBooleanDefault:
        'Boolean prop should not set a default (Vue defaults it to false).',
      defaultFalse: 'Boolean prop should only be defaulted to false.'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    const booleanType = context.options[0] || 'no-default'
    /**
     * @param {ComponentProp} prop
     * @param { { [key: string]: Expression | undefined } } [withDefaultsExpressions]
     */
    function processProp(prop, withDefaultsExpressions) {
      if (prop.type === 'object') {
        if (prop.value.type !== 'ObjectExpression') {
          return
        }
        if (!prop.value.properties.some(isBooleanProp)) {
          return
        }
        const defaultNode = getDefaultNode(prop.value)
        if (!defaultNode) {
          return
        }
        verifyDefaultExpression(defaultNode.value)
      } else if (prop.type === 'type') {
        if (prop.types.length !== 1 || prop.types[0] !== 'Boolean') {
          return
        }
        const defaultNode =
          withDefaultsExpressions && withDefaultsExpressions[prop.propName]
        if (!defaultNode) {
          return
        }
        verifyDefaultExpression(defaultNode)
      }
    }
    /**
     * @param {ComponentProp[]} props
     * @param { { [key: string]: Expression | undefined } } [withDefaultsExpressions]
     */
    function processProps(props, withDefaultsExpressions) {
      for (const prop of props) {
        processProp(prop, withDefaultsExpressions)
      }
    }

    /**
     * @param {Expression} defaultNode
     */
    function verifyDefaultExpression(defaultNode) {
      switch (booleanType) {
        case 'no-default': {
          context.report({
            node: defaultNode,
            messageId: 'noBooleanDefault'
          })
          break
        }

        case 'default-false': {
          if (defaultNode.type !== 'Literal' || defaultNode.value !== false) {
            context.report({
              node: defaultNode,
              messageId: 'defaultFalse'
            })
          }
          break
        }
      }
    }
    return utils.compositingVisitors(
      utils.executeOnVueComponent(context, (obj) => {
        processProps(utils.getComponentPropsFromOptions(obj))
      }),
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(node, props) {
          processProps(props, utils.getWithDefaultsPropExpressions(node))
        }
      })
    )
  }
}
