/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'

const utils = require('../utils')
const scopeAttribute = require('./syntaxes/scope-attribute')

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow deprecated `scope` attribute (in Vue.js 2.5.0+)',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/no-deprecated-scope-attribute.html'
    },
    fixable: 'code',
    schema: [],
    messages: {
      forbiddenScopeAttribute: '`scope` attributes are deprecated.'
    }
  },
  create (context) {
    const templateBodyVisitor = scopeAttribute.createTemplateBodyVisitor(context)
    return utils.defineTemplateBodyVisitor(context, templateBodyVisitor)
  }
}
