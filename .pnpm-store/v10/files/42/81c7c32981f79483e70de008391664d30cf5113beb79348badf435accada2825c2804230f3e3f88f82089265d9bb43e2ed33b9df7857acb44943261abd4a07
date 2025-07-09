'use strict'

const baseRule = require('./block-order')

module.exports = {
  // eslint-disable-next-line eslint-plugin/require-meta-schema, eslint-plugin/prefer-message-ids -- inherit schema from base rule
  meta: {
    ...baseRule.meta,
    // eslint-disable-next-line eslint-plugin/meta-property-ordering
    type: baseRule.meta.type,
    docs: {
      description: baseRule.meta.docs.description,
      categories: ['vue3-recommended', 'vue2-recommended'],
      url: 'https://eslint.vuejs.org/rules/component-tags-order.html'
    },
    deprecated: true,
    replacedBy: ['block-order']
  },
  /** @param {RuleContext} context */
  create(context) {
    return baseRule.create(context)
  }
}
