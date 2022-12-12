/**
 * @fileoverview Don't introduce side effects in computed properties
 * @author Michał Sajnóg
 */
'use strict'

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'disallow side effects in computed properties',
      category: 'essential',
      url: 'https://eslint.vuejs.org/rules/no-side-effects-in-computed-properties.html'
    },
    fixable: null,
    schema: []
  },

  create (context) {
    const forbiddenNodes = []
    let scopeStack = { upper: null, body: null }

    function onFunctionEnter (node) {
      scopeStack = { upper: scopeStack, body: node.body }
    }

    function onFunctionExit () {
      scopeStack = scopeStack.upper
    }

    return Object.assign({},
      {
        ':function': onFunctionEnter,
        ':function:exit': onFunctionExit,

        // this.xxx <=|+=|-=>
        'AssignmentExpression' (node) {
          if (node.left.type !== 'MemberExpression') return
          if (utils.parseMemberExpression(node.left)[0] === 'this') {
            forbiddenNodes.push({
              node,
              targetBody: scopeStack.body
            })
          }
        },
        // this.xxx <++|-->
        'UpdateExpression > MemberExpression' (node) {
          if (utils.parseMemberExpression(node)[0] === 'this') {
            forbiddenNodes.push({
              node,
              targetBody: scopeStack.body
            })
          }
        },
        // this.xxx.func()
        'CallExpression' (node) {
          const code = utils.parseMemberOrCallExpression(node)
          const MUTATION_REGEX = /(this.)((?!(concat|slice|map|filter)\().)[^\)]*((push|pop|shift|unshift|reverse|splice|sort|copyWithin|fill)\()/g

          if (MUTATION_REGEX.test(code)) {
            forbiddenNodes.push({
              node,
              targetBody: scopeStack.body
            })
          }
        }
      },
      utils.executeOnVue(context, (obj) => {
        const computedProperties = utils.getComputedProperties(obj)

        computedProperties.forEach(cp => {
          forbiddenNodes.forEach(({ node, targetBody }) => {
            if (
              cp.value &&
              node.loc.start.line >= cp.value.loc.start.line &&
              node.loc.end.line <= cp.value.loc.end.line &&
              targetBody === cp.value
            ) {
              context.report({
                node: node,
                message: 'Unexpected side effect in "{{key}}" computed property.',
                data: { key: cp.key }
              })
            }
          })
        })
      })
    )
  }
}
