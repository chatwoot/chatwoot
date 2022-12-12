/**
 * @fileoverview Require default value for props
 * @author Michał Sajnóg <msajnog93@gmail.com> (https://github.com/michalsnik)
 */
'use strict'

/**
 * @typedef {import('vue-eslint-parser').AST.ESLintExpression} Expression
 * @typedef {import('vue-eslint-parser').AST.ESLintObjectExpression} ObjectExpression
 * @typedef {import('vue-eslint-parser').AST.ESLintPattern} Pattern
 */
/**
 * @typedef {import('../utils').ComponentObjectProp} ComponentObjectProp
 * @typedef {ComponentObjectProp & { value: ObjectExpression} } ComponentObjectPropObject
 */

const utils = require('../utils')

const NATIVE_TYPES = new Set([
  'String',
  'Number',
  'Boolean',
  'Function',
  'Object',
  'Array',
  'Symbol'
])

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'require default value for props',
      category: 'strongly-recommended',
      url: 'https://eslint.vuejs.org/rules/require-default-prop.html'
    },
    fixable: null, // or "code" or "whitespace"
    schema: []
  },

  create (context) {
    // ----------------------------------------------------------------------
    // Helpers
    // ----------------------------------------------------------------------

    /**
     * Checks if the passed prop is required
     * @param {ComponentObjectPropObject} prop - Property AST node for a single prop
     * @return {boolean}
     */
    function propIsRequired (prop) {
      const propRequiredNode = prop.value.properties
        .find(p =>
          p.type === 'Property' &&
          utils.getStaticPropertyName(p) === 'required' &&
          p.value.type === 'Literal' &&
          p.value.value === true
        )

      return Boolean(propRequiredNode)
    }

    /**
     * Checks if the passed prop has a default value
     * @param {ComponentObjectPropObject} prop - Property AST node for a single prop
     * @return {boolean}
     */
    function propHasDefault (prop) {
      const propDefaultNode = prop.value.properties
        .find(p =>
          p.type === 'Property' && utils.getStaticPropertyName(p) === 'default'
        )

      return Boolean(propDefaultNode)
    }

    /**
     * Finds all props that don't have a default value set
     * @param {ComponentObjectProp[]} props - Vue component's "props" node
     * @return {ComponentObjectProp[]} Array of props without "default" value
     */
    function findPropsWithoutDefaultValue (props) {
      return props
        .filter(prop => {
          if (prop.value.type !== 'ObjectExpression') {
            return (prop.value.type !== 'CallExpression' && prop.value.type !== 'Identifier') ||
              (prop.value.type === 'Identifier' && NATIVE_TYPES.has(prop.value.name))
          }

          return !propIsRequired(/** @type {ComponentObjectPropObject} */(prop)) && !propHasDefault(/** @type {ComponentObjectPropObject} */(prop))
        })
    }

    /**
     * Detects whether given value node is a Boolean type
     * @param {Expression | Pattern} value
     * @return {Boolean}
     */
    function isValueNodeOfBooleanType (value) {
      return (
        value.type === 'Identifier' &&
        value.name === 'Boolean'
      ) || (
        value.type === 'ArrayExpression' &&
        value.elements.length === 1 &&
        value.elements[0].type === 'Identifier' &&
        value.elements[0].name === 'Boolean'
      )
    }

    /**
     * Detects whether given prop node is a Boolean
     * @param {ComponentObjectProp} prop
     * @return {Boolean}
     */
    function isBooleanProp (prop) {
      const value = utils.unwrapTypes(prop.value)

      return isValueNodeOfBooleanType(value) || (
        value.type === 'ObjectExpression' &&
        value.properties.some(p =>
          p.type === 'Property' &&
          p.key.type === 'Identifier' &&
          p.key.name === 'type' &&
          isValueNodeOfBooleanType(p.value)
        )
      )
    }

    /**
     * Excludes purely Boolean props from the Array
     * @param {ComponentObjectProp[]} props - Array with props
     * @return {ComponentObjectProp[]}
     */
    function excludeBooleanProps (props) {
      return props.filter(prop => !isBooleanProp(prop))
    }

    // ----------------------------------------------------------------------
    // Public
    // ----------------------------------------------------------------------

    return utils.executeOnVue(context, (obj) => {
      const props = utils.getComponentProps(obj)
        .filter(prop => prop.key && prop.value && !(prop.node.type === 'Property' && prop.node.shorthand))

      const propsWithoutDefault = findPropsWithoutDefaultValue(/** @type {ComponentObjectProp[]} */(props))
      const propsToReport = excludeBooleanProps(propsWithoutDefault)

      for (const prop of propsToReport) {
        const propName = prop.propName != null ? prop.propName : `[${context.getSourceCode().getText(prop.key)}]`

        context.report({
          node: prop.node,
          message: `Prop '{{propName}}' requires default value to be set.`,
          data: {
            propName
          }
        })
      }
    })
  }
}
