/**
 * @fileoverview Require default value for props
 * @author Michał Sajnóg <msajnog93@gmail.com> (https://github.com/michalsnik)
 */
'use strict'

/**
 * @typedef {import('../utils').ComponentProp} ComponentProp
 * @typedef {import('../utils').ComponentObjectProp} ComponentObjectProp
 * @typedef {ComponentObjectProp & { value: ObjectExpression} } ComponentObjectPropObject
 */

const utils = require('../utils')
const { isDef } = require('../utils')

const NATIVE_TYPES = new Set([
  'String',
  'Number',
  'Boolean',
  'Function',
  'Object',
  'Array',
  'Symbol'
])

/**
 * Detects whether given value node is a Boolean type
 * @param {Expression} value
 * @return {boolean}
 */
function isValueNodeOfBooleanType(value) {
  if (value.type === 'Identifier' && value.name === 'Boolean') {
    return true
  }
  if (value.type === 'ArrayExpression') {
    const elements = value.elements.filter(isDef)
    return (
      elements.length === 1 &&
      elements[0].type === 'Identifier' &&
      elements[0].name === 'Boolean'
    )
  }
  return false
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require default value for props',
      categories: ['vue3-strongly-recommended', 'vue2-strongly-recommended'],
      url: 'https://eslint.vuejs.org/rules/require-default-prop.html'
    },
    fixable: null,
    schema: [],
    messages: {
      missingDefault: `Prop '{{propName}}' requires default value to be set.`
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    /**
     * Checks if the passed prop is required
     * @param {ObjectExpression} propValue - ObjectExpression AST node for a single prop
     * @return {boolean}
     */
    function propIsRequired(propValue) {
      const propRequiredNode = propValue.properties.find(
        (p) =>
          p.type === 'Property' &&
          utils.getStaticPropertyName(p) === 'required' &&
          p.value.type === 'Literal' &&
          p.value.value === true
      )

      return Boolean(propRequiredNode)
    }

    /**
     * Checks if the passed prop has a default value
     * @param {ObjectExpression} propValue - ObjectExpression AST node for a single prop
     * @return {boolean}
     */
    function propHasDefault(propValue) {
      const propDefaultNode = propValue.properties.find(
        (p) =>
          p.type === 'Property' && utils.getStaticPropertyName(p) === 'default'
      )

      return Boolean(propDefaultNode)
    }

    /**
     * Checks whether the given props that don't have a default value
     * @param {ComponentObjectProp} prop Vue component's "props" node
     * @return {boolean}
     */
    function isWithoutDefaultValue(prop) {
      if (prop.value.type !== 'ObjectExpression') {
        if (prop.value.type === 'Identifier') {
          return NATIVE_TYPES.has(prop.value.name)
        }
        if (
          prop.value.type === 'CallExpression' ||
          prop.value.type === 'MemberExpression'
        ) {
          // OK
          return false
        }
        // NG
        return true
      }

      return !propIsRequired(prop.value) && !propHasDefault(prop.value)
    }

    /**
     * Detects whether given prop node is a Boolean
     * @param {ComponentObjectProp} prop
     * @return {Boolean}
     */
    function isBooleanProp(prop) {
      const value = utils.skipTSAsExpression(prop.value)

      return (
        isValueNodeOfBooleanType(value) ||
        (value.type === 'ObjectExpression' &&
          value.properties.some(
            (p) =>
              p.type === 'Property' &&
              p.key.type === 'Identifier' &&
              p.key.name === 'type' &&
              isValueNodeOfBooleanType(p.value)
          ))
      )
    }

    /**
     * @param {ComponentProp[]} props
     * @param {boolean} [withDefaults]
     * @param { { [key: string]: Expression | undefined } } [withDefaultsExpressions]
     */
    function processProps(props, withDefaults, withDefaultsExpressions) {
      for (const prop of props) {
        if (prop.type === 'object' && !prop.node.shorthand) {
          if (!isWithoutDefaultValue(prop)) {
            continue
          }
          if (isBooleanProp(prop)) {
            continue
          }
          const propName =
            prop.propName == null
              ? `[${context.getSourceCode().getText(prop.node.key)}]`
              : prop.propName

          context.report({
            node: prop.node,
            messageId: `missingDefault`,
            data: {
              propName
            }
          })
        } else if (
          prop.type === 'type' &&
          withDefaults &&
          withDefaultsExpressions
        ) {
          if (prop.required) {
            continue
          }
          if (prop.types.length === 1 && prop.types[0] === 'Boolean') {
            continue
          }
          if (!withDefaultsExpressions[prop.propName]) {
            context.report({
              node: prop.node,
              messageId: `missingDefault`,
              data: {
                propName: prop.propName
              }
            })
          }
        }
      }
    }

    return utils.compositingVisitors(
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(node, props) {
          processProps(
            props,
            utils.hasWithDefaults(node),
            utils.getWithDefaultsPropExpressions(node)
          )
        }
      }),
      utils.executeOnVue(context, (obj) => {
        processProps(utils.getComponentPropsFromOptions(obj))
      })
    )
  }
}
