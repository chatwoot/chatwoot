/**
 * @author Niklas Higi
 */
'use strict'

const utils = require('../utils')

/**
 * @typedef { import('../utils').ComponentPropertyData } ComponentPropertyData
 */

/**
 * Check whether the given token is a quote.
 * @param {Token} token The token to check.
 * @returns {boolean} `true` if the token is a quote.
 */
function isQuote(token) {
  return (
    token != null &&
    token.type === 'Punctuator' &&
    (token.value === '"' || token.value === "'")
  )
}

/**
 * @param {VOnExpression} node
 * @returns {CallExpression | null}
 */
function getInvalidNeverCallExpression(node) {
  /** @type {ExpressionStatement} */
  let exprStatement
  let body = node.body
  while (true) {
    const statements = body.filter((st) => st.type !== 'EmptyStatement')
    if (statements.length !== 1) {
      return null
    }
    const statement = statements[0]
    if (statement.type === 'ExpressionStatement') {
      exprStatement = statement
      break
    }
    if (statement.type === 'BlockStatement') {
      body = statement.body
      continue
    }
    return null
  }
  const expression = exprStatement.expression
  if (expression.type !== 'CallExpression' || expression.arguments.length > 0) {
    return null
  }
  if (expression.optional) {
    // Allow optional chaining
    return null
  }
  const callee = expression.callee
  if (callee.type !== 'Identifier') {
    return null
  }
  return expression
}

module.exports = {
  meta: {
    type: 'suggestion',
    docs: {
      description:
        'enforce or forbid parentheses after method calls without arguments in `v-on` directives',
      categories: undefined,
      url: 'https://eslint.vuejs.org/rules/v-on-function-call.html'
    },
    fixable: 'code',
    deprecated: true,
    replacedBy: ['v-on-handler-style'],
    schema: [
      { enum: ['always', 'never'] },
      {
        type: 'object',
        properties: {
          ignoreIncludesComment: {
            type: 'boolean'
          }
        },
        additionalProperties: false
      }
    ],
    messages: {
      always: "Method calls inside of 'v-on' directives must have parentheses.",
      never:
        "Method calls without arguments inside of 'v-on' directives must not have parentheses."
    }
  },
  /** @param {RuleContext} context */
  create(context) {
    const always = context.options[0] === 'always'

    if (always) {
      return utils.defineTemplateBodyVisitor(context, {
        /** @param {Identifier} node */
        "VAttribute[directive=true][key.name.name='on'][key.argument!=null] > VExpressionContainer > Identifier"(
          node
        ) {
          context.report({
            node,
            messageId: 'always'
          })
        }
      })
    }

    const option = context.options[1] || {}
    const ignoreIncludesComment = !!option.ignoreIncludesComment
    /** @type {Set<string>} */
    const useArgsMethods = new Set()

    return utils.defineTemplateBodyVisitor(
      context,
      {
        /** @param {VOnExpression} node */
        "VAttribute[directive=true][key.name.name='on'][key.argument!=null] VOnExpression"(
          node
        ) {
          const expression = getInvalidNeverCallExpression(node)
          if (!expression) {
            return
          }

          const sourceCode = context.getSourceCode()
          const tokenStore =
            sourceCode.parserServices.getTemplateBodyTokenStore()
          const tokens = tokenStore.getTokens(node.parent, {
            includeComments: true
          })
          /** @type {Token | undefined} */
          let leftQuote
          /** @type {Token | undefined} */
          let rightQuote
          if (isQuote(tokens[0])) {
            leftQuote = tokens.shift()
            rightQuote = tokens.pop()
          }

          const hasComment = tokens.some(
            (token) => token.type === 'Block' || token.type === 'Line'
          )

          if (ignoreIncludesComment && hasComment) {
            return
          }

          if (
            expression.callee.type === 'Identifier' &&
            useArgsMethods.has(expression.callee.name)
          ) {
            // The behavior of target method can change given the arguments.
            return
          }

          context.report({
            node: expression,
            messageId: 'never',
            fix: hasComment
              ? null /* The comment is included and cannot be fixed. */
              : (fixer) => {
                  /** @type {Range} */
                  const range =
                    leftQuote && rightQuote
                      ? [leftQuote.range[1], rightQuote.range[0]]
                      : [tokens[0].range[0], tokens[tokens.length - 1].range[1]]

                  return fixer.replaceTextRange(
                    range,
                    context.getSourceCode().getText(expression.callee)
                  )
                }
          })
        }
      },
      utils.defineVueVisitor(context, {
        onVueObjectEnter(node) {
          for (const method of utils.iterateProperties(
            node,
            new Set(['methods'])
          )) {
            if (useArgsMethods.has(method.name)) {
              continue
            }
            if (method.type !== 'object') {
              continue
            }
            const value = method.property.value
            if (
              (value.type === 'FunctionExpression' ||
                value.type === 'ArrowFunctionExpression') &&
              value.params.length > 0
            ) {
              useArgsMethods.add(method.name)
            }
          }
        }
      })
    )
  }
}
