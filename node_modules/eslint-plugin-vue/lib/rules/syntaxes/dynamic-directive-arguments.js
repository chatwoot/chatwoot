/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'
module.exports = {
  supported: '2.6.0',
  createTemplateBodyVisitor (context) {
    /**
     * Reports dynamic argument node
     * @param {VExpressionContainer} dinamicArgument node of dynamic argument
     * @returns {void}
     */
    function reportDynamicArgument (dinamicArgument) {
      context.report({
        node: dinamicArgument,
        messageId: 'forbiddenDynamicDirectiveArguments'
      })
    }

    return {
      'VAttribute[directive=true] > VDirectiveKey > VExpressionContainer': reportDynamicArgument
    }
  }
}
