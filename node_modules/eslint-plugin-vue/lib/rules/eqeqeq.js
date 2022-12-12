/**
 * @author Toru Nagashima
 */
'use strict'

const { wrapCoreRule } = require('../utils')

// eslint-disable-next-line
module.exports = wrapCoreRule(require('eslint/lib/rules/eqeqeq'))
