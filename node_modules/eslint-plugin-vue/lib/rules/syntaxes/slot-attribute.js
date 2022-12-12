/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'
module.exports = {
  deprecated: '2.6.0',
  createTemplateBodyVisitor (context) {
    const sourceCode = context.getSourceCode()

    /**
     * Checks whether the given node can convert to the `v-slot`.
     * @param {VAttribute} slotAttr node of `slot`
     * @returns {boolean} `true` if the given node can convert to the `v-slot`
     */
    function canConvertFromSlotToVSlot (slotAttr) {
      if (slotAttr.parent.parent.name !== 'template') {
        return false
      }
      if (!slotAttr.value) {
        return true
      }
      const slotName = slotAttr.value.value
      // If non-Latin characters are included it can not be converted.
      return !/[^a-z]/i.test(slotName)
    }

    /**
     * Checks whether the given node can convert to the `v-slot`.
     * @param {VAttribute} slotAttr node of `v-bind:slot`
     * @returns {boolean} `true` if the given node can convert to the `v-slot`
     */
    function canConvertFromVBindSlotToVSlot (slotAttr) {
      if (slotAttr.parent.parent.name !== 'template') {
        return false
      }

      if (!slotAttr.value) {
        return true
      }

      if (!slotAttr.value.expression) {
        // parse error or empty expression
        return false
      }
      const slotName = sourceCode.getText(slotAttr.value.expression).trim()
      // If non-Latin characters are included it can not be converted.
      // It does not check the space only because `a>b?c:d` should be rejected.
      return !/[^a-z]/i.test(slotName)
    }

    /**
     * Convert to `v-slot`.
     * @param {object} fixer fixer
     * @param {VAttribute} slotAttr node of `slot`
     * @param {string | null} slotName name of `slot`
     * @param {boolean} vBind `true` if `slotAttr` is `v-bind:slot`
     * @returns {*} fix data
     */
    function fixSlotToVSlot (fixer, slotAttr, slotName, vBind) {
      const element = slotAttr.parent
      const scopeAttr = element.attributes
        .find(attr => attr.directive === true && attr.key.name && (
          attr.key.name.name === 'slot-scope' ||
          attr.key.name.name === 'scope'
        ))
      const nameArgument = slotName ? (vBind ? `:[${slotName}]` : `:${slotName}`) : ''
      const scopeValue = scopeAttr && scopeAttr.value
        ? `=${sourceCode.getText(scopeAttr.value)}`
        : ''

      const replaceText = `v-slot${nameArgument}${scopeValue}`
      const fixers = [
        fixer.replaceText(slotAttr || scopeAttr, replaceText)
      ]
      if (slotAttr && scopeAttr) {
        fixers.push(fixer.remove(scopeAttr))
      }
      return fixers
    }
    /**
     * Reports `slot` node
     * @param {VAttribute} slotAttr node of `slot`
     * @returns {void}
     */
    function reportSlot (slotAttr) {
      context.report({
        node: slotAttr.key,
        messageId: 'forbiddenSlotAttribute',
        // fix to use `v-slot`
        fix (fixer) {
          if (!canConvertFromSlotToVSlot(slotAttr)) {
            return null
          }
          const slotName = slotAttr.value &&
            slotAttr.value.value
          return fixSlotToVSlot(fixer, slotAttr, slotName, false)
        }
      })
    }
    /**
     * Reports `v-bind:slot` node
     * @param {VAttribute} slotAttr node of `v-bind:slot`
     * @returns {void}
     */
    function reportVBindSlot (slotAttr) {
      context.report({
        node: slotAttr.key,
        messageId: 'forbiddenSlotAttribute',
        // fix to use `v-slot`
        fix (fixer) {
          if (!canConvertFromVBindSlotToVSlot(slotAttr)) {
            return null
          }
          const slotName = slotAttr.value &&
            slotAttr.value.expression &&
            sourceCode.getText(slotAttr.value.expression).trim()
          return fixSlotToVSlot(fixer, slotAttr, slotName, true)
        }
      })
    }

    return {
      "VAttribute[directive=false][key.name='slot']": reportSlot,
      "VAttribute[directive=true][key.name.name='bind'][key.argument.name='slot']": reportVBindSlot
    }
  }
}
