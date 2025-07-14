'use strict'

const baseRule = require('./valid-model-definition')

module.exports = {
  // eslint-disable-next-line eslint-plugin/prefer-message-ids
  meta: {
    ...baseRule.meta,
    // eslint-disable-next-line eslint-plugin/meta-property-ordering
    type: baseRule.meta.type,
    docs: {
      description: baseRule.meta.docs.description,
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-invalid-model-keys.html'
    },
    deprecated: true,
    replacedBy: ['valid-model-definition'],
    schema: []
  },
  /** @param {RuleContext} context */
  create(context) {
    return baseRule.create(context)
  }
}
