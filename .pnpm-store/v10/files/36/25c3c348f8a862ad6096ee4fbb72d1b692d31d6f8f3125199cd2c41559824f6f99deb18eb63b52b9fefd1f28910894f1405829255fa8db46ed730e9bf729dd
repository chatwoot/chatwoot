/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'
const baseRule = require('./no-setup-props-reactivity-loss')

module.exports = {
  // eslint-disable-next-line eslint-plugin/require-meta-schema, eslint-plugin/prefer-message-ids, internal/no-invalid-meta, eslint-plugin/require-meta-type -- inherit schema from base rule
  meta: {
    ...baseRule.meta,
    // eslint-disable-next-line eslint-plugin/require-meta-docs-description, internal/no-invalid-meta-docs-categories, eslint-plugin/meta-property-ordering
    docs: {
      ...baseRule.meta.docs,
      url: 'https://eslint.vuejs.org/rules/no-setup-props-destructure.html'
    },
    deprecated: true,
    replacedBy: ['no-setup-props-reactivity-loss']
  },
  /** @param {RuleContext} context */
  create(context) {
    return baseRule.create(context)
  }
}
