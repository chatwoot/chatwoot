/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'
const { Range } = require('semver')
const unsupported = new Range('<=2.5 || >=2.6.0')

module.exports = {
  // >=2.6.0-beta.1 <=2.6.0-beta.3
  supported: (versionRange) => {
    return !versionRange.intersects(unsupported)
  },
  createTemplateBodyVisitor (context) {
    /**
     * Reports `.prop` shorthand node
     * @param {VDirectiveKey} bindPropKey node of `.prop` shorthand
     * @returns {void}
     */
    function reportPropModifierShorthand (bindPropKey) {
      context.report({
        node: bindPropKey,
        messageId: 'forbiddenVBindPropModifierShorthand',
        // fix to use `:x.prop` (downgrade)
        fix: fixer => fixer.replaceText(bindPropKey, `:${bindPropKey.argument.rawName}.prop`)
      })
    }

    return {
      "VAttribute[directive=true] > VDirectiveKey[name.name='bind'][name.rawName='.']": reportPropModifierShorthand
    }
  }
}
