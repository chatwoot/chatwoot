/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'

const utils = require('../utils')
const slotScopeAttribute = require('./syntaxes/slot-scope-attribute')

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow deprecated `slot-scope` attribute (in Vue.js 2.6.0+)',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/no-deprecated-slot-scope-attribute.html'
    },
    fixable: 'code',
    schema: [],
    messages: {
      forbiddenSlotScopeAttribute: '`slot-scope` are deprecated.'
    }
  },
  create (context) {
    const templateBodyVisitor = slotScopeAttribute.createTemplateBodyVisitor(context, { fixToUpgrade: true })
    return utils.defineTemplateBodyVisitor(context, templateBodyVisitor)
  }
}
