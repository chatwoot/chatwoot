// Source copied and then modified from
// https://github.com/remarkjs/remark/blob/master/packages/remark-parse/lib/tokenize/html-block.js
//
// MIT License https://github.com/remarkjs/remark/blob/master/license

const {openCloseTag} = require('./tag')

module.exports = blockHtml

const tab = '\t'
const space = ' '
const lineFeed = '\n'
const lessThan = '<'

const rawOpenExpression = /^<(script|pre|style)(?=(\s|>|$))/i
const rawCloseExpression = /<\/(script|pre|style)>/i
const commentOpenExpression = /^<!--/
const commentCloseExpression = /-->/
const instructionOpenExpression = /^<\?/
const instructionCloseExpression = /\?>/
const directiveOpenExpression = /^<![A-Za-z]/
const directiveCloseExpression = />/
const cdataOpenExpression = /^<!\[CDATA\[/
const cdataCloseExpression = /\]\]>/
const elementCloseExpression = /^$/
const otherElementOpenExpression = new RegExp(openCloseTag.source + '\\s*$')
const fragmentOpenExpression = /^<>/

function blockHtml(eat, value, silent) {
  const blocks = '[a-z\\.]*(\\.){0,1}[a-z][a-z0-9\\.]*'
  const elementOpenExpression = new RegExp(
    '^</?(' + blocks + ')(?=(\\s|/?>|$))',
    'i'
  )

  const length = value.length
  let index = 0
  let next
  let line
  let offset
  let character
  let count
  let sequence
  let subvalue

  const sequences = [
    [rawOpenExpression, rawCloseExpression, true],
    [commentOpenExpression, commentCloseExpression, true],
    [instructionOpenExpression, instructionCloseExpression, true],
    [directiveOpenExpression, directiveCloseExpression, true],
    [cdataOpenExpression, cdataCloseExpression, true],
    [elementOpenExpression, elementCloseExpression, true],
    [fragmentOpenExpression, elementCloseExpression, true],
    [otherElementOpenExpression, elementCloseExpression, false]
  ]

  // Eat initial spacing.
  while (index < length) {
    character = value.charAt(index)

    if (character !== tab && character !== space) {
      break
    }

    index++
  }

  if (value.charAt(index) !== lessThan) {
    return
  }

  next = value.indexOf(lineFeed, index + 1)
  next = next === -1 ? length : next
  line = value.slice(index, next)
  offset = -1
  count = sequences.length

  while (++offset < count) {
    if (sequences[offset][0].test(line)) {
      sequence = sequences[offset]
      break
    }
  }

  if (!sequence) {
    return
  }

  if (silent) {
    return sequence[2]
  }

  index = next

  if (!sequence[1].test(line)) {
    while (index < length) {
      next = value.indexOf(lineFeed, index + 1)
      next = next === -1 ? length : next
      line = value.slice(index + 1, next)

      if (sequence[1].test(line)) {
        if (line) {
          index = next
        }

        break
      }

      index = next
    }
  }

  subvalue = value.slice(0, index)

  return eat(subvalue)({type: 'html', value: subvalue})
}
