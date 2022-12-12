/**
 * @author Yosuke Ota
 * @fileoverview Rule to check for max length on a line of Vue file.
 */
'use strict'

// ------------------------------------------------------------------------------
// Requirements
// ------------------------------------------------------------------------------

const utils = require('../utils')

// ------------------------------------------------------------------------------
// Constants
// ------------------------------------------------------------------------------

const OPTIONS_SCHEMA = {
  type: 'object',
  properties: {
    code: {
      type: 'integer',
      minimum: 0
    },
    template: {
      type: 'integer',
      minimum: 0
    },
    comments: {
      type: 'integer',
      minimum: 0
    },
    tabWidth: {
      type: 'integer',
      minimum: 0
    },
    ignorePattern: {
      type: 'string'
    },
    ignoreComments: {
      type: 'boolean'
    },
    ignoreTrailingComments: {
      type: 'boolean'
    },
    ignoreUrls: {
      type: 'boolean'
    },
    ignoreStrings: {
      type: 'boolean'
    },
    ignoreTemplateLiterals: {
      type: 'boolean'
    },
    ignoreRegExpLiterals: {
      type: 'boolean'
    },
    ignoreHTMLAttributeValues: {
      type: 'boolean'
    },
    ignoreHTMLTextContents: {
      type: 'boolean'
    }
  },
  additionalProperties: false
}

const OPTIONS_OR_INTEGER_SCHEMA = {
  anyOf: [
    OPTIONS_SCHEMA,
    {
      type: 'integer',
      minimum: 0
    }
  ]
}

// --------------------------------------------------------------------------
// Helpers
// --------------------------------------------------------------------------

/**
 * Computes the length of a line that may contain tabs. The width of each
 * tab will be the number of spaces to the next tab stop.
 * @param {string} line The line.
 * @param {int} tabWidth The width of each tab stop in spaces.
 * @returns {int} The computed line length.
 * @private
 */
function computeLineLength (line, tabWidth) {
  let extraCharacterCount = 0

  line.replace(/\t/gu, (match, offset) => {
    const totalOffset = offset + extraCharacterCount
    const previousTabStopOffset = tabWidth ? totalOffset % tabWidth : 0
    const spaceCount = tabWidth - previousTabStopOffset

    extraCharacterCount += spaceCount - 1 // -1 for the replaced tab
  })
  return Array.from(line).length + extraCharacterCount
}

/**
 * Tells if a given comment is trailing: it starts on the current line and
 * extends to or past the end of the current line.
 * @param {string} line The source line we want to check for a trailing comment on
 * @param {number} lineNumber The one-indexed line number for line
 * @param {ASTNode} comment The comment to inspect
 * @returns {boolean} If the comment is trailing on the given line
 */
function isTrailingComment (line, lineNumber, comment) {
  return comment &&
              (comment.loc.start.line === lineNumber && lineNumber <= comment.loc.end.line) &&
              (comment.loc.end.line > lineNumber || comment.loc.end.column === line.length)
}

/**
 * Tells if a comment encompasses the entire line.
 * @param {string} line The source line with a trailing comment
 * @param {number} lineNumber The one-indexed line number this is on
 * @param {ASTNode} comment The comment to remove
 * @returns {boolean} If the comment covers the entire line
 */
function isFullLineComment (line, lineNumber, comment) {
  const start = comment.loc.start
  const end = comment.loc.end
  const isFirstTokenOnLine = !line.slice(0, comment.loc.start.column).trim()

  return comment &&
              (start.line < lineNumber || (start.line === lineNumber && isFirstTokenOnLine)) &&
              (end.line > lineNumber || (end.line === lineNumber && end.column === line.length))
}

/**
 * Gets the line after the comment and any remaining trailing whitespace is
 * stripped.
 * @param {string} line The source line with a trailing comment
 * @param {ASTNode} comment The comment to remove
 * @returns {string} Line without comment and trailing whitepace
 */
function stripTrailingComment (line, comment) {
  // loc.column is zero-indexed
  return line.slice(0, comment.loc.start.column).replace(/\s+$/u, '')
}

/**
 * Ensure that an array exists at [key] on `object`, and add `value` to it.
 *
 * @param {Object} object the object to mutate
 * @param {string} key the object's key
 * @param {*} value the value to add
 * @returns {void}
 * @private
 */
function ensureArrayAndPush (object, key, value) {
  if (!Array.isArray(object[key])) {
    object[key] = []
  }
  object[key].push(value)
}

/**
 * A reducer to group an AST node by line number, both start and end.
 *
 * @param {Object} acc the accumulator
 * @param {ASTNode} node the AST node in question
 * @returns {Object} the modified accumulator
 * @private
 */
function groupByLineNumber (acc, node) {
  for (let i = node.loc.start.line; i <= node.loc.end.line; ++i) {
    ensureArrayAndPush(acc, i, node)
  }
  return acc
}

// ------------------------------------------------------------------------------
// Rule Definition
// ------------------------------------------------------------------------------

module.exports = {
  meta: {
    type: 'layout',

    docs: {
      description: 'enforce a maximum line length',
      category: undefined,
      url: 'https://eslint.vuejs.org/rules/max-len.html'
    },

    schema: [
      OPTIONS_OR_INTEGER_SCHEMA,
      OPTIONS_OR_INTEGER_SCHEMA,
      OPTIONS_SCHEMA
    ],
    messages: {
      max: 'This line has a length of {{lineLength}}. Maximum allowed is {{maxLength}}.',
      maxComment: 'This line has a comment length of {{lineLength}}. Maximum allowed is {{maxCommentLength}}.'
    }
  },

  create (context) {
    /*
     * Inspired by http://tools.ietf.org/html/rfc3986#appendix-B, however:
     * - They're matching an entire string that we know is a URI
     * - We're matching part of a string where we think there *might* be a URL
     * - We're only concerned about URLs, as picking out any URI would cause
     *   too many false positives
     * - We don't care about matching the entire URL, any small segment is fine
     */
    const URL_REGEXP = /[^:/?#]:\/\/[^?#]/u

    const sourceCode = context.getSourceCode()
    const tokens = []
    const comments = []
    const htmlAttributeValues = []

    // The options object must be the last option specified…
    const options = Object.assign({}, context.options[context.options.length - 1])

    // …but max code length…
    if (typeof context.options[0] === 'number') {
      options.code = context.options[0]
    }

    // …and tabWidth can be optionally specified directly as integers.
    if (typeof context.options[1] === 'number') {
      options.tabWidth = context.options[1]
    }

    const scriptMaxLength = typeof options.code === 'number' ? options.code : 80
    const tabWidth = typeof options.tabWidth === 'number' ? options.tabWidth : 2// default value of `vue/html-indent`
    const templateMaxLength = typeof options.template === 'number' ? options.template : scriptMaxLength
    const ignoreComments = !!options.ignoreComments
    const ignoreStrings = !!options.ignoreStrings
    const ignoreTemplateLiterals = !!options.ignoreTemplateLiterals
    const ignoreRegExpLiterals = !!options.ignoreRegExpLiterals
    const ignoreTrailingComments = !!options.ignoreTrailingComments || !!options.ignoreComments
    const ignoreUrls = !!options.ignoreUrls
    const ignoreHTMLAttributeValues = !!options.ignoreHTMLAttributeValues
    const ignoreHTMLTextContents = !!options.ignoreHTMLTextContents
    const maxCommentLength = options.comments
    let ignorePattern = options.ignorePattern || null

    if (ignorePattern) {
      ignorePattern = new RegExp(ignorePattern, 'u')
    }

    // --------------------------------------------------------------------------
    // Helpers
    // --------------------------------------------------------------------------

    /**
     * Retrieves an array containing all strings (" or ') in the source code.
     *
     * @returns {ASTNode[]} An array of string nodes.
     */
    function getAllStrings () {
      return tokens.filter(token => (token.type === 'String' ||
              (token.type === 'JSXText' && sourceCode.getNodeByRangeIndex(token.range[0] - 1).type === 'JSXAttribute')))
    }

    /**
     * Retrieves an array containing all template literals in the source code.
     *
     * @returns {ASTNode[]} An array of template literal nodes.
     */
    function getAllTemplateLiterals () {
      return tokens.filter(token => token.type === 'Template')
    }

    /**
     * Retrieves an array containing all RegExp literals in the source code.
     *
     * @returns {ASTNode[]} An array of RegExp literal nodes.
     */
    function getAllRegExpLiterals () {
      return tokens.filter(token => token.type === 'RegularExpression')
    }

    /**
     * Retrieves an array containing all HTML texts in the source code.
     *
     * @returns {ASTNode[]} An array of HTML text nodes.
     */
    function getAllHTMLTextContents () {
      return tokens.filter(token => token.type === 'HTMLText')
    }

    /**
     * Check the program for max length
     * @param {ASTNode} node Node to examine
     * @returns {void}
     * @private
     */
    function checkProgramForMaxLength (node) {
      const programNode = node
      const templateBody = node.templateBody

      // setup tokens
      const scriptTokens = sourceCode.ast.tokens
      const scriptComments = sourceCode.getAllComments()

      if (context.parserServices.getTemplateBodyTokenStore && templateBody) {
        const tokenStore = context.parserServices.getTemplateBodyTokenStore()

        const templateTokens = tokenStore.getTokens(templateBody, { includeComments: true })

        if (templateBody.range[0] < programNode.range[0]) {
          tokens.push(...templateTokens, ...scriptTokens)
        } else {
          tokens.push(...scriptTokens, ...templateTokens)
        }
      } else {
        tokens.push(...scriptTokens)
      }

      if (ignoreComments || maxCommentLength || ignoreTrailingComments) {
        // list of comments to ignore
        if (templateBody) {
          if (templateBody.range[0] < programNode.range[0]) {
            comments.push(...templateBody.comments, ...scriptComments)
          } else {
            comments.push(...scriptComments, ...templateBody.comments)
          }
        } else {
          comments.push(...scriptComments)
        }
      }

      let scriptLinesRange
      if (scriptTokens.length) {
        if (scriptComments.length) {
          scriptLinesRange = [
            Math.min(scriptTokens[0].loc.start.line, scriptComments[0].loc.start.line),
            Math.max(scriptTokens[scriptTokens.length - 1].loc.end.line, scriptComments[scriptComments.length - 1].loc.end.line)
          ]
        } else {
          scriptLinesRange = [
            scriptTokens[0].loc.start.line,
            scriptTokens[scriptTokens.length - 1].loc.end.line
          ]
        }
      } else if (scriptComments.length) {
        scriptLinesRange = [
          scriptComments[0].loc.start.line,
          scriptComments[scriptComments.length - 1].loc.end.line
        ]
      }
      const templateLinesRange = templateBody && [templateBody.loc.start.line, templateBody.loc.end.line]

      // split (honors line-ending)
      const lines = sourceCode.lines

      const strings = getAllStrings()
      const stringsByLine = strings.reduce(groupByLineNumber, {})

      const templateLiterals = getAllTemplateLiterals()
      const templateLiteralsByLine = templateLiterals.reduce(groupByLineNumber, {})

      const regExpLiterals = getAllRegExpLiterals()
      const regExpLiteralsByLine = regExpLiterals.reduce(groupByLineNumber, {})

      const htmlAttributeValuesByLine = htmlAttributeValues.reduce(groupByLineNumber, {})

      const htmlTextContents = getAllHTMLTextContents()
      const htmlTextContentsByLine = htmlTextContents.reduce(groupByLineNumber, {})

      const commentsByLine = comments.reduce(groupByLineNumber, {})

      lines.forEach((line, i) => {
        // i is zero-indexed, line numbers are one-indexed
        const lineNumber = i + 1

        const inScript = (scriptLinesRange && scriptLinesRange[0] <= lineNumber && lineNumber <= scriptLinesRange[1])
        const inTemplate = (templateLinesRange && templateLinesRange[0] <= lineNumber && lineNumber <= templateLinesRange[1])
        // check if line is inside a script or template.
        if (!inScript && !inTemplate) {
          // out of range.
          return
        }
        const maxLength = inScript && inTemplate
          ? Math.max(scriptMaxLength, templateMaxLength)
          : inScript
            ? scriptMaxLength
            : templateMaxLength

        if (
          (ignoreStrings && stringsByLine[lineNumber]) ||
          (ignoreTemplateLiterals && templateLiteralsByLine[lineNumber]) ||
          (ignoreRegExpLiterals && regExpLiteralsByLine[lineNumber]) ||
          (ignoreHTMLAttributeValues && htmlAttributeValuesByLine[lineNumber]) ||
          (ignoreHTMLTextContents && htmlTextContentsByLine[lineNumber])
        ) {
          // ignore this line
          return
        }

        /*
         * if we're checking comment length; we need to know whether this
         * line is a comment
         */
        let lineIsComment = false
        let textToMeasure

        /*
         * comments to check.
         */
        if (commentsByLine[lineNumber]) {
          const commentList = [...commentsByLine[lineNumber]]

          let comment = commentList.pop()

          if (isFullLineComment(line, lineNumber, comment)) {
            lineIsComment = true
            textToMeasure = line
          } else if (ignoreTrailingComments && isTrailingComment(line, lineNumber, comment)) {
            textToMeasure = stripTrailingComment(line, comment)

            // ignore multiple trailing comments in the same line
            comment = commentList.pop()

            while (isTrailingComment(textToMeasure, lineNumber, comment)) {
              textToMeasure = stripTrailingComment(textToMeasure, comment)
            }
          } else {
            textToMeasure = line
          }
        } else {
          textToMeasure = line
        }

        if ((ignorePattern && ignorePattern.test(textToMeasure)) ||
            (ignoreUrls && URL_REGEXP.test(textToMeasure))) {
          // ignore this line
          return
        }

        const lineLength = computeLineLength(textToMeasure, tabWidth)
        const commentLengthApplies = lineIsComment && maxCommentLength

        if (lineIsComment && ignoreComments) {
          return
        }

        if (commentLengthApplies) {
          if (lineLength > maxCommentLength) {
            context.report({
              node,
              loc: { line: lineNumber, column: 0 },
              messageId: 'maxComment',
              data: {
                lineLength,
                maxCommentLength
              }
            })
          }
        } else if (lineLength > maxLength) {
          context.report({
            node,
            loc: { line: lineNumber, column: 0 },
            messageId: 'max',
            data: {
              lineLength,
              maxLength
            }
          })
        }
      })
    }

    // --------------------------------------------------------------------------
    // Public API
    // --------------------------------------------------------------------------

    const bodyVisitor = utils.defineTemplateBodyVisitor(context,
      {
        'VAttribute[directive=false] > VLiteral' (node) {
          htmlAttributeValues.push(node)
        }
      }
    )

    return Object.assign({}, bodyVisitor,
      {
        'Program:exit' (node) {
          if (bodyVisitor['Program:exit']) {
            bodyVisitor['Program:exit'](node)
          }
          checkProgramForMaxLength(node)
        }
      }
    )
  }
}
