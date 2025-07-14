/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'

const { extractRefObjectReferences } = require('../utils/ref-object-references')
const utils = require('../utils')

/**
 * @typedef {import('../utils/ref-object-references').RefObjectReferences} RefObjectReferences
 * @typedef {import('../utils/ref-object-references').RefObjectReferenceForIdentifier} RefObjectReferenceForIdentifier
 */

/**
 * Checks whether the given identifier reference has been initialized with a ref object.
 * @param {RefObjectReferenceForIdentifier | null} data
 * @returns {data is RefObjectReferenceForIdentifier}
 */
function isRefInit(data) {
  const init = data && data.variableDeclarator && data.variableDeclarator.init
  if (!init) {
    return false
  }
  return data.defineChain.includes(/** @type {any} */ (init))
}
module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'disallow use of value wrapped by `ref()` (Composition API) as an operand',
      categories: ['vue3-essential', 'vue2-essential'],
      url: 'https://eslint.vuejs.org/rules/no-ref-as-operand.html'
    },
    fixable: 'code',
    schema: [],
    messages: {
      requireDotValue:
        'Must use `.value` to read or write the value wrapped by `{{method}}()`.'
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    /** @type {RefObjectReferences} */
    let refReferences

    /**
     * @param {Identifier} node
     */
    function reportIfRefWrapped(node) {
      const data = refReferences.get(node)
      if (!isRefInit(data)) {
        return
      }
      context.report({
        node,
        messageId: 'requireDotValue',
        data: {
          method: data.method
        },
        fix(fixer) {
          return fixer.insertTextAfter(node, '.value')
        }
      })
    }
    return {
      Program() {
        refReferences = extractRefObjectReferences(context)
      },
      // if (refValue)
      /** @param {Identifier} node */
      'IfStatement>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // switch (refValue)
      /** @param {Identifier} node */
      'SwitchStatement>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // -refValue, +refValue, !refValue, ~refValue, typeof refValue
      /** @param {Identifier} node */
      'UnaryExpression>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // refValue++, refValue--
      /** @param {Identifier} node */
      'UpdateExpression>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // refValue+1, refValue-1
      /** @param {Identifier} node */
      'BinaryExpression>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // refValue+=1, refValue-=1, foo+=refValue, foo-=refValue
      /** @param {Identifier & {parent: AssignmentExpression}} node */
      'AssignmentExpression>Identifier'(node) {
        if (node.parent.operator === '=' && node.parent.left !== node) {
          return
        }
        reportIfRefWrapped(node)
      },
      // refValue || other, refValue && other. ignore: other || refValue
      /** @param {Identifier & {parent: LogicalExpression}} node */
      'LogicalExpression>Identifier'(node) {
        if (node.parent.left !== node) {
          return
        }
        // Report only constants.
        const data = refReferences.get(node)
        if (
          !data ||
          !data.variableDeclaration ||
          data.variableDeclaration.kind !== 'const'
        ) {
          return
        }
        reportIfRefWrapped(node)
      },
      // refValue ? x : y
      /** @param {Identifier & {parent: ConditionalExpression}} node */
      'ConditionalExpression>Identifier'(node) {
        if (node.parent.test !== node) {
          return
        }
        reportIfRefWrapped(node)
      },
      // `${refValue}`
      /** @param {Identifier} node */
      'TemplateLiteral>Identifier'(node) {
        reportIfRefWrapped(node)
      },
      // refValue.x
      /** @param {Identifier & {parent: MemberExpression}} node */
      'MemberExpression>Identifier'(node) {
        if (node.parent.object !== node) {
          return
        }
        const name = utils.getStaticPropertyName(node.parent)
        if (
          name === 'value' ||
          name == null ||
          // WritableComputedRef
          name === 'effect'
        ) {
          return
        }
        reportIfRefWrapped(node)
      }
    }
  }
}
