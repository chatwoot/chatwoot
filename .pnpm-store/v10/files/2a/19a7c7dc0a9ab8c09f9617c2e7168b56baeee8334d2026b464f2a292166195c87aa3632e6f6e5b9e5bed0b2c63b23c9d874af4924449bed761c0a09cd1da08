/**
 * @fileoverview Disable inheritAttrs when using v-bind="$attrs"
 * @author Hiroki Osame
 */
'use strict'

const utils = require('../utils')

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'enforce `inheritAttrs` to be set to `false` when using `v-bind="$attrs"`',
      categories: undefined,
      recommended: false,
      url: 'https://eslint.vuejs.org/rules/no-duplicate-attr-inheritance.html'
    },
    fixable: null,
    schema: [],
    messages: {
      noDuplicateAttrInheritance: 'Set "inheritAttrs" to false.'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    /** @type {string | number | boolean | RegExp | BigInt | null} */
    let inheritsAttrs = true

    /** @param {ObjectExpression} node */
    function processOptions(node) {
      const inheritAttrsProp = utils.findProperty(node, 'inheritAttrs')

      if (inheritAttrsProp && inheritAttrsProp.value.type === 'Literal') {
        inheritsAttrs = inheritAttrsProp.value.value
      }
    }

    return utils.compositingVisitors(
      utils.executeOnVue(context, processOptions),
      utils.defineScriptSetupVisitor(context, {
        onDefineOptionsEnter(node) {
          if (node.arguments.length === 0) return
          const define = node.arguments[0]
          if (define.type !== 'ObjectExpression') return
          processOptions(define)
        }
      }),
      utils.defineTemplateBodyVisitor(context, {
        /** @param {VExpressionContainer} node */
        "VAttribute[directive=true][key.name.name='bind'][key.argument=null] > VExpressionContainer"(
          node
        ) {
          if (!inheritsAttrs) {
            return
          }
          const attrsRef = node.references.find((reference) => {
            if (reference.variable != null) {
              // Not vm reference
              return false
            }
            return reference.id.name === '$attrs'
          })

          if (attrsRef) {
            context.report({
              node: attrsRef.id,
              messageId: 'noDuplicateAttrInheritance'
            })
          }
        }
      })
    )
  }
}
