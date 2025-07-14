/**
 * @author Yosuke Ota
 * See LICENSE file in root directory for full license.
 */
'use strict'
const { findVariable } = require('@eslint-community/eslint-utils')
const utils = require('../utils')

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'disallow usages that lose the reactivity of `props` passed to `setup`',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/no-setup-props-reactivity-loss.html'
    },
    fixable: null,
    schema: [],
    messages: {
      destructuring:
        'Destructuring the `props` will cause the value to lose reactivity.',
      getProperty:
        'Getting a value from the `props` in root scope of `{{scopeName}}` will cause the value to lose reactivity.'
    }
  },
  /**
   * @param {RuleContext} context
   * @returns {RuleListener}
   **/
  create(context) {
    /**
     * @typedef {object} ScopePropsReferences
     * @property {Set<Identifier>} refs
     * @property {string} scopeName
     */
    /** @type {Map<FunctionDeclaration | FunctionExpression | ArrowFunctionExpression | Program, ScopePropsReferences>} */
    const setupScopePropsReferenceIds = new Map()
    const wrapperExpressionTypes = new Set([
      'ArrayExpression',
      'ObjectExpression'
    ])

    /**
     * @param {ESNode} node
     * @param {string} messageId
     * @param {string} scopeName
     */
    function report(node, messageId, scopeName) {
      context.report({
        node,
        messageId,
        data: {
          scopeName
        }
      })
    }

    /**
     * @param {Pattern} left
     * @param {Expression | null} right
     * @param {ScopePropsReferences} propsReferences
     */
    function verify(left, right, propsReferences) {
      if (!right) {
        return
      }

      const rightNode = utils.skipChainExpression(right)

      if (
        wrapperExpressionTypes.has(rightNode.type) &&
        isPropsMemberAccessed(rightNode, propsReferences)
      ) {
        return report(rightNode, 'getProperty', propsReferences.scopeName)
      }

      if (
        left.type !== 'ArrayPattern' &&
        left.type !== 'ObjectPattern' &&
        rightNode.type !== 'MemberExpression' &&
        rightNode.type !== 'ConditionalExpression' &&
        rightNode.type !== 'TemplateLiteral'
      ) {
        return
      }

      if (rightNode.type === 'TemplateLiteral') {
        rightNode.expressions.some((expression) =>
          checkMemberAccess(expression, propsReferences, left, right)
        )
      } else {
        checkMemberAccess(rightNode, propsReferences, left, right)
      }
    }

    /**
     * @param {Expression | Super} rightId
     * @param {ScopePropsReferences} propsReferences
     * @param {Pattern} left
     * @param {Expression} right
     * @return {boolean}
     */
    function checkMemberAccess(rightId, propsReferences, left, right) {
      while (rightId.type === 'MemberExpression') {
        rightId = utils.skipChainExpression(rightId.object)
      }
      if (rightId.type === 'Identifier' && propsReferences.refs.has(rightId)) {
        report(left, 'getProperty', propsReferences.scopeName)
        return true
      }
      if (
        rightId.type === 'ConditionalExpression' &&
        (isPropsMemberAccessed(rightId.test, propsReferences) ||
          isPropsMemberAccessed(rightId.consequent, propsReferences) ||
          isPropsMemberAccessed(rightId.alternate, propsReferences))
      ) {
        report(right, 'getProperty', propsReferences.scopeName)
        return true
      }
      return false
    }

    /**
     * @param {Expression} node
     * @param {ScopePropsReferences} propsReferences
     */
    function isPropsMemberAccessed(node, propsReferences) {
      const propRefs = [...propsReferences.refs.values()]

      return propRefs.some((props) => {
        const isPropsInExpressionRange = utils.inRange(node.range, props)
        const isPropsMemberExpression =
          props.parent.type === 'MemberExpression' &&
          props.parent.object === props

        return isPropsInExpressionRange && isPropsMemberExpression
      })
    }

    /**
     * @typedef {object} ScopeStack
     * @property {ScopeStack | null} upper
     * @property {FunctionDeclaration | FunctionExpression | ArrowFunctionExpression | Program} scopeNode
     */
    /**
     * @type {ScopeStack | null}
     */
    let scopeStack = null

    /**
     * @param {Pattern | null} node
     * @param {FunctionDeclaration | FunctionExpression | ArrowFunctionExpression | Program} scopeNode
     * @param {import('eslint').Scope.Scope} currentScope
     * @param {string} scopeName
     */
    function processPattern(node, scopeNode, currentScope, scopeName) {
      if (!node) {
        // no arguments
        return
      }
      if (
        node.type === 'RestElement' ||
        node.type === 'AssignmentPattern' ||
        node.type === 'MemberExpression'
      ) {
        // cannot check
        return
      }
      if (node.type === 'ArrayPattern' || node.type === 'ObjectPattern') {
        report(node, 'destructuring', scopeName)
        return
      }

      const variable = findVariable(currentScope, node)
      if (!variable) {
        return
      }
      const propsReferenceIds = new Set()
      for (const reference of variable.references) {
        // If reference is in another scope, we can't check it.
        if (reference.from !== currentScope) {
          continue
        }

        if (!reference.isRead()) {
          continue
        }

        propsReferenceIds.add(reference.identifier)
      }
      setupScopePropsReferenceIds.set(scopeNode, {
        refs: propsReferenceIds,
        scopeName
      })
    }
    return utils.compositingVisitors(
      {
        /**
         * @param {FunctionExpression | FunctionDeclaration | ArrowFunctionExpression | Program} node
         */
        'Program, :function'(node) {
          scopeStack = {
            upper: scopeStack,
            scopeNode: node
          }
        },
        /**
         * @param {FunctionExpression | FunctionDeclaration | ArrowFunctionExpression | Program} node
         */
        'Program, :function:exit'(node) {
          scopeStack = scopeStack && scopeStack.upper

          setupScopePropsReferenceIds.delete(node)
        },
        /**
         * @param {CallExpression} node
         */
        CallExpression(node) {
          if (!scopeStack) {
            return
          }

          const propsReferenceIds = setupScopePropsReferenceIds.get(
            scopeStack.scopeNode
          )

          if (!propsReferenceIds) {
            return
          }

          if (isPropsMemberAccessed(node, propsReferenceIds)) {
            report(node, 'getProperty', propsReferenceIds.scopeName)
          }
        },
        /**
         * @param {VariableDeclarator} node
         */
        VariableDeclarator(node) {
          if (!scopeStack) {
            return
          }
          const propsReferenceIds = setupScopePropsReferenceIds.get(
            scopeStack.scopeNode
          )
          if (!propsReferenceIds) {
            return
          }
          verify(node.id, node.init, propsReferenceIds)
        },
        /**
         * @param {AssignmentExpression} node
         */
        AssignmentExpression(node) {
          if (!scopeStack) {
            return
          }
          const propsReferenceIds = setupScopePropsReferenceIds.get(
            scopeStack.scopeNode
          )
          if (!propsReferenceIds) {
            return
          }
          verify(node.left, node.right, propsReferenceIds)
        }
      },
      utils.defineScriptSetupVisitor(context, {
        onDefinePropsEnter(node) {
          let target = node
          if (
            target.parent &&
            target.parent.type === 'CallExpression' &&
            target.parent.arguments[0] === target &&
            target.parent.callee.type === 'Identifier' &&
            target.parent.callee.name === 'withDefaults'
          ) {
            target = target.parent
          }
          if (!target.parent) {
            return
          }

          /** @type {Pattern|null} */
          let id = null
          if (target.parent.type === 'VariableDeclarator') {
            id = target.parent.init === target ? target.parent.id : null
          } else if (target.parent.type === 'AssignmentExpression') {
            id = target.parent.right === target ? target.parent.left : null
          }
          const currentScope = utils.getScope(context, node)
          processPattern(
            id,
            context.getSourceCode().ast,
            currentScope,
            '<script setup>'
          )
        }
      }),
      utils.defineVueVisitor(context, {
        onSetupFunctionEnter(node) {
          const currentScope = utils.getScope(context, node)
          const propsParam = utils.skipDefaultParamValue(node.params[0])
          processPattern(propsParam, node, currentScope, 'setup()')
        }
      })
    )
  }
}
