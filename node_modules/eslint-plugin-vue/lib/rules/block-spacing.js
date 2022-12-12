/**
 * @author Yosuke Ota
 */
'use strict'

const { wrapCoreRule } = require('../utils')

// eslint-disable-next-line no-invalid-meta
module.exports = wrapCoreRule(
  require('eslint/lib/rules/block-spacing'),
  { skipDynamicArguments: true }
)
