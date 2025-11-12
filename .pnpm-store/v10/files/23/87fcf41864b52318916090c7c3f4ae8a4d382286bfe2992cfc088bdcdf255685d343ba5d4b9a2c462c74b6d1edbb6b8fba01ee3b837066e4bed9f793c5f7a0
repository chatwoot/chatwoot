/**
 * @author Doug Wade <douglas.b.wade@gmail.com>
 */

'use strict'

const utils = require('../utils')

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow specific HTML elements',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-restricted-html-elements.html'
    },
    fixable: null,
    schema: {
      type: 'array',
      items: {
        oneOf: [
          { type: 'string' },
          {
            type: 'object',
            properties: {
              element: { type: 'string' },
              message: { type: 'string', minLength: 1 }
            },
            required: ['element'],
            additionalProperties: false
          }
        ]
      },
      uniqueItems: true,
      minItems: 0
    },
    messages: {
      forbiddenElement: 'Unexpected use of forbidden HTML element {{name}}.',
      // eslint-disable-next-line eslint-plugin/report-message-format
      customMessage: '{{message}}'
    }
  },
  /**
   * @param {RuleContext} context - The rule context.
   * @returns {RuleListener} AST event handlers.
   */
  create(context) {
    return utils.defineTemplateBodyVisitor(context, {
      /**
       * @param {VElement} node
       */
      VElement(node) {
        if (!utils.isHtmlElementNode(node)) {
          return
        }

        for (const option of context.options) {
          const element = option.element || option

          if (element === node.rawName) {
            context.report({
              messageId: option.message ? 'customMessage' : 'forbiddenElement',
              data: {
                name: node.rawName,
                message: option.message
              },
              node: node.startTag
            })
          }
        }
      }
    })
  }
}
