/**
 * @author kevsommer Kevin Sommer
 * See LICENSE file in root directory for full license.
 */
'use strict'
const utils = require('../utils')

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'enforce maximum number of props in Vue component',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/max-props.html'
    },
    fixable: null,
    schema: [
      {
        type: 'object',
        properties: {
          maxProps: {
            type: 'integer',
            minimum: 1
          }
        },
        additionalProperties: false,
        minProperties: 1
      }
    ],
    messages: {
      tooManyProps:
        'Component has too many props ({{propCount}}). Maximum allowed is {{limit}}.'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    /** @type {Record<string, number>} */
    const option = context.options[0] || {}

    /**
     * @param {import('../utils').ComponentProp[]} props
     */
    function checkMaxNumberOfProps(props) {
      if (props.length > option.maxProps && props[0].node) {
        context.report({
          node: props[0].node.parent,
          messageId: 'tooManyProps',
          data: {
            propCount: props.length,
            limit: option.maxProps
          }
        })
      }
    }

    return utils.compositingVisitors(
      utils.executeOnVue(context, (obj) => {
        checkMaxNumberOfProps(utils.getComponentPropsFromOptions(obj))
      }),
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(_, props) {
          checkMaxNumberOfProps(props)
        }
      })
    )
  }
}
