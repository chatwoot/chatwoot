/**
 * @author Toru Nagashima
 */
'use strict'

const { wrapCoreRule } = require('../utils')

// eslint-disable-next-line no-invalid-meta
module.exports = wrapCoreRule(
  require('eslint/lib/rules/space-infix-ops'),
  { skipDynamicArguments: true }
)
