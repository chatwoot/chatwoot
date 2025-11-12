/**
 * @fileoverview Requires specific casing for the Prop name in Vue components
 * @author Yu Kimura
 */
'use strict'

const utils = require('../utils')
const casing = require('../utils/casing')
const allowedCaseOptions = ['camelCase', 'snake_case']

/**
 * @typedef {import('../utils').ComponentProp} ComponentProp
 */

/** @param {RuleContext} context */
function create(context) {
  const options = context.options[0]
  const caseType = allowedCaseOptions.includes(options) ? options : 'camelCase'
  const checker = casing.getChecker(caseType)

  /**
   * @param {ComponentProp[]} props
   */
  function processProps(props) {
    for (const item of props) {
      const propName = item.propName
      if (propName == null) {
        continue
      }
      if (!checker(propName)) {
        context.report({
          node: item.node,
          messageId: 'invalidCase',
          data: {
            name: propName,
            caseType
          }
        })
      }
    }
  }
  return utils.compositingVisitors(
    utils.defineScriptSetupVisitor(context, {
      onDefinePropsEnter(_node, props) {
        processProps(props)
      }
    }),
    utils.executeOnVue(context, (obj) => {
      processProps(utils.getComponentPropsFromOptions(obj))
    })
  )
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'enforce specific casing for the Prop name in Vue components',
      categories: ['vue3-strongly-recommended', 'vue2-strongly-recommended'],
      url: 'https://eslint.vuejs.org/rules/prop-name-casing.html'
    },
    fixable: null, // null or "code" or "whitespace"
    schema: [
      {
        enum: allowedCaseOptions
      }
    ],
    messages: {
      invalidCase: 'Prop "{{name}}" is not in {{caseType}}.'
    }
  },
  create
}
