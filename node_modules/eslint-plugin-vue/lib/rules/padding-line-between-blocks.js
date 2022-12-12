/**
 * @fileoverview Require or disallow padding lines between blocks
 * @author Yosuke Ota
 */
'use strict'
const utils = require('../utils')

/**
 * Split the source code into multiple lines based on the line delimiters.
 * @param {string} text Source code as a string.
 * @returns {string[]} Array of source code lines.
 */
function splitLines (text) {
  return text.split(/\r\n|[\r\n\u2028\u2029]/gu)
}

/**
 * Check and report blocks for `never` configuration.
 * This autofix removes blank lines between the given 2 blocks.
 * @param {RuleContext} context The rule context to report.
 * @param {VElement} prevBlock The previous block to check.
 * @param {VElement} nextBlock The next block to check.
 * @param {Token[]} betweenTokens The array of tokens between blocks.
 * @returns {void}
 * @private
 */
function verifyForNever (context, prevBlock, nextBlock, betweenTokens) {
  if (prevBlock.loc.end.line === nextBlock.loc.start.line) {
    // same line
    return
  }
  const tokenOrNodes = [...betweenTokens, nextBlock]
  let prev = prevBlock
  const paddingLines = []
  for (const tokenOrNode of tokenOrNodes) {
    const numOfLineBreaks = tokenOrNode.loc.start.line - prev.loc.end.line
    if (numOfLineBreaks > 1) {
      paddingLines.push([prev, tokenOrNode])
    }
    prev = tokenOrNode
  }
  if (!paddingLines.length) {
    return
  }

  context.report({
    node: nextBlock,
    messageId: 'never',
    fix (fixer) {
      return paddingLines.map(([prevToken, nextToken]) => {
        const start = prevToken.range[1]
        const end = nextToken.range[0]
        const paddingText = context.getSourceCode().text
          .slice(start, end)
        const lastSpaces = splitLines(paddingText).pop()
        return fixer.replaceTextRange([start, end], '\n' + lastSpaces)
      })
    }
  })
}

/**
 * Check and report blocks for `always` configuration.
 * This autofix inserts a blank line between the given 2 blocks.
 * @param {RuleContext} context The rule context to report.
 * @param {VElement} prevBlock The previous block to check.
 * @param {VElement} nextBlock The next block to check.
 * @param {Token[]} betweenTokens The array of tokens between blocks.
 * @returns {void}
 * @private
 */
function verifyForAlways (context, prevBlock, nextBlock, betweenTokens) {
  const tokenOrNodes = [...betweenTokens, nextBlock]
  let prev = prevBlock
  let linebreak
  for (const tokenOrNode of tokenOrNodes) {
    const numOfLineBreaks = tokenOrNode.loc.start.line - prev.loc.end.line
    if (numOfLineBreaks > 1) {
      // Already padded.
      return
    }
    if (!linebreak && numOfLineBreaks > 0) {
      linebreak = prev
    }
    prev = tokenOrNode
  }

  context.report({
    node: nextBlock,
    messageId: 'always',
    fix (fixer) {
      if (linebreak) {
        return fixer.insertTextAfter(linebreak, '\n')
      }
      return fixer.insertTextAfter(prevBlock, '\n\n')
    }
  })
}

/**
 * Types of blank lines.
 * `never` and `always` are defined.
 * Those have `verify` method to check and report statements.
 * @private
 */
const PaddingTypes = {
  never: { verify: verifyForNever },
  always: { verify: verifyForAlways }
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',
    docs: {
      description: 'require or disallow padding lines between blocks',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/padding-line-between-blocks.html'
    },
    fixable: 'whitespace',
    schema: [
      {
        enum: Object.keys(PaddingTypes)
      }
    ],
    messages: {
      never: 'Unexpected blank line before this block.',
      always: 'Expected blank line before this block.'
    }
  },
  create (context) {
    const paddingType = PaddingTypes[context.options[0] || 'always']
    const documentFragment = context.parserServices.getDocumentFragment && context.parserServices.getDocumentFragment()

    let tokens
    function getTopLevelHTMLElements () {
      if (documentFragment) {
        return documentFragment.children.filter(e => e.type === 'VElement')
      }
      return []
    }

    function getTokenAndCommentsBetween (prev, next) {
      // When there is no <template>, tokenStore.getTokensBetween cannot be used.
      if (!tokens) {
        tokens = [
          ...documentFragment.tokens
            .filter(token => token.type !== 'HTMLWhitespace'),
          ...documentFragment.comments
        ].sort((a, b) => a.range[0] > b.range[0] ? 1 : a.range[0] < b.range[0] ? -1 : 0)
      }

      let token = tokens.shift()

      const results = []
      while (token) {
        if (prev.range[1] <= token.range[0]) {
          if (next.range[0] <= token.range[0]) {
            tokens.unshift(token)
            break
          } else {
            results.push(token)
          }
        }
        token = tokens.shift()
      }

      return results
    }

    return utils.defineTemplateBodyVisitor(
      context,
      {},
      {
        Program (node) {
          if (utils.hasInvalidEOF(node)) {
            return
          }
          const elements = [...getTopLevelHTMLElements()]

          let prev = elements.shift()
          for (const element of elements) {
            const betweenTokens = getTokenAndCommentsBetween(prev, element)
            paddingType.verify(context, prev, element, betweenTokens)
            prev = element
          }
        }
      }
    )
  }
}
