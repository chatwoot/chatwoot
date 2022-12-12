'use strict'

module.exports = footnotes

var tab = 9 // '\t'
var lineFeed = 10 // '\n'
var space = 32
var exclamationMark = 33 // '!'
var colon = 58 // ':'
var leftSquareBracket = 91 // '['
var backslash = 92 // '\'
var rightSquareBracket = 93 // ']'
var caret = 94 // '^'
var graveAccent = 96 //  '`'

var tabSize = 4
var maxSlice = 1024

function footnotes(options) {
  var parser = this.Parser
  var compiler = this.Compiler

  if (isRemarkParser(parser)) {
    attachParser(parser, options)
  }

  if (isRemarkCompiler(compiler)) {
    attachCompiler(compiler)
  }
}

function isRemarkParser(parser) {
  return Boolean(parser && parser.prototype && parser.prototype.blockTokenizers)
}

function isRemarkCompiler(compiler) {
  return Boolean(compiler && compiler.prototype && compiler.prototype.visitors)
}

function attachParser(parser, options) {
  var settings = options || {}
  var proto = parser.prototype
  var blocks = proto.blockTokenizers
  var spans = proto.inlineTokenizers
  var blockMethods = proto.blockMethods
  var inlineMethods = proto.inlineMethods
  var originalDefinition = blocks.definition
  var originalReference = spans.reference
  var interruptors = []
  var index = -1
  var length = blockMethods.length
  var method

  // Interrupt by anything except for indented code or paragraphs.
  while (++index < length) {
    method = blockMethods[index]

    if (
      method === 'newline' ||
      method === 'indentedCode' ||
      method === 'paragraph' ||
      method === 'footnoteDefinition'
    ) {
      continue
    }

    interruptors.push([method])
  }

  interruptors.push(['footnoteDefinition'])

  // Insert tokenizers.
  if (settings.inlineNotes) {
    before(inlineMethods, 'reference', 'inlineNote')
    spans.inlineNote = footnote
  }

  before(blockMethods, 'definition', 'footnoteDefinition')
  before(inlineMethods, 'reference', 'footnoteCall')

  blocks.definition = definition
  blocks.footnoteDefinition = footnoteDefinition
  spans.footnoteCall = footnoteCall
  spans.reference = reference

  proto.interruptFootnoteDefinition = interruptors
  reference.locator = originalReference.locator
  footnoteCall.locator = locateFootnoteCall
  footnote.locator = locateFootnote

  function footnoteDefinition(eat, value, silent) {
    var self = this
    var interruptors = self.interruptFootnoteDefinition
    var offsets = self.offset
    var length = value.length + 1
    var index = 0
    var content = []
    var label
    var labelStart
    var labelEnd
    var code
    var now
    var add
    var exit
    var children
    var start
    var indent
    var contentStart
    var lines
    var line

    // Skip initial whitespace.
    while (index < length) {
      code = value.charCodeAt(index)
      if (code !== tab && code !== space) break
      index++
    }

    // Parse `[^`.
    if (value.charCodeAt(index++) !== leftSquareBracket) return
    if (value.charCodeAt(index++) !== caret) return

    // Parse label.
    labelStart = index

    while (index < length) {
      code = value.charCodeAt(index)

      // Exit on white space.
      if (
        code !== code ||
        code === lineFeed ||
        code === tab ||
        code === space
      ) {
        return
      }

      if (code === rightSquareBracket) {
        labelEnd = index
        index++
        break
      }

      index++
    }

    // Exit if we didn’t find an end, no label, or there’s no colon.
    if (
      labelEnd === undefined ||
      labelStart === labelEnd ||
      value.charCodeAt(index++) !== colon
    ) {
      return
    }

    // Found it!
    /* istanbul ignore if - never used (yet) */
    if (silent) {
      return true
    }

    label = value.slice(labelStart, labelEnd)

    // Now, to get all lines.
    now = eat.now()
    start = 0
    indent = 0
    contentStart = index
    lines = []

    while (index < length) {
      code = value.charCodeAt(index)

      if (code !== code || code === lineFeed) {
        line = {
          start: start,
          contentStart: contentStart || index,
          contentEnd: index,
          end: index
        }

        lines.push(line)

        // Prepare a new line.
        if (code === lineFeed) {
          start = index + 1
          indent = 0
          contentStart = undefined

          line.end = start
        }
      } else if (indent !== undefined) {
        if (code === space || code === tab) {
          indent += code === space ? 1 : tabSize - (indent % tabSize)

          if (indent > tabSize) {
            indent = undefined
            contentStart = index
          }
        } else {
          // If this line is not indented and it’s either preceded by a blank
          // line or starts a new block, exit.
          if (
            indent < tabSize &&
            line &&
            (line.contentStart === line.contentEnd ||
              interrupt(interruptors, blocks, self, [
                eat,
                value.slice(index, maxSlice),
                true
              ]))
          ) {
            break
          }

          indent = undefined
          contentStart = index
        }
      }

      index++
    }

    // Remove trailing lines without content.
    index = -1
    length = lines.length

    while (length > 0) {
      line = lines[length - 1]

      if (line.contentStart !== line.contentEnd) {
        break
      }

      length--
    }

    // Add all, but ignore the final line feed.
    add = eat(value.slice(0, line.contentEnd))

    // Add indent offsets and get content w/o indents.
    while (++index < length) {
      line = lines[index]

      offsets[now.line + index] =
        (offsets[now.line + index] || 0) + (line.contentStart - line.start)

      content.push(value.slice(line.contentStart, line.end))
    }

    // Parse content.
    exit = self.enterBlock()
    children = self.tokenizeBlock(content.join(''), now)
    exit()

    return add({
      type: 'footnoteDefinition',
      identifier: label.toLowerCase(),
      label: label,
      children: children
    })
  }

  // Parse a footnote call / footnote reference, such as `[^label]`
  function footnoteCall(eat, value, silent) {
    var length = value.length + 1
    var index = 0
    var label
    var labelStart
    var labelEnd
    var code

    if (value.charCodeAt(index++) !== leftSquareBracket) return
    if (value.charCodeAt(index++) !== caret) return

    labelStart = index

    while (index < length) {
      code = value.charCodeAt(index)

      if (
        code !== code ||
        code === lineFeed ||
        code === tab ||
        code === space
      ) {
        return
      }

      if (code === rightSquareBracket) {
        labelEnd = index
        index++
        break
      }

      index++
    }

    if (labelEnd === undefined || labelStart === labelEnd) {
      return
    }

    /* istanbul ignore if - never used (yet) */
    if (silent) {
      return true
    }

    label = value.slice(labelStart, labelEnd)

    return eat(value.slice(0, index))({
      type: 'footnoteReference',
      identifier: label.toLowerCase(),
      label: label
    })
  }

  // Parse an inline note / footnote, such as `^[text]`
  function footnote(eat, value, silent) {
    var self = this
    var length = value.length + 1
    var index = 0
    var balance = 0
    var now
    var code
    var contentStart
    var contentEnd
    var fenceStart
    var fenceOpenSize
    var fenceCloseSize

    if (value.charCodeAt(index++) !== caret) return
    if (value.charCodeAt(index++) !== leftSquareBracket) return

    contentStart = index

    while (index < length) {
      code = value.charCodeAt(index)

      // EOF:
      if (code !== code) {
        return
      }

      // If we’re not in code:
      if (fenceOpenSize === undefined) {
        if (code === backslash) {
          index += 2
        } else if (code === leftSquareBracket) {
          balance++
          index++
        } else if (code === rightSquareBracket) {
          if (balance === 0) {
            contentEnd = index
            index++
            break
          } else {
            balance--
            index++
          }
        } else if (code === graveAccent) {
          fenceStart = index
          fenceOpenSize = 1

          while (value.charCodeAt(fenceStart + fenceOpenSize) === graveAccent) {
            fenceOpenSize++
          }

          index += fenceOpenSize
        } else {
          index++
        }
      }
      // We’re in code:
      else {
        if (code === graveAccent) {
          fenceStart = index
          fenceCloseSize = 1

          while (
            value.charCodeAt(fenceStart + fenceCloseSize) === graveAccent
          ) {
            fenceCloseSize++
          }

          index += fenceCloseSize

          // Found it, we’re no longer in code!
          if (fenceOpenSize === fenceCloseSize) {
            fenceOpenSize = undefined
          }

          fenceCloseSize = undefined
        } else {
          index++
        }
      }
    }

    if (contentEnd === undefined) {
      return
    }

    /* istanbul ignore if - never used (yet) */
    if (silent) {
      return true
    }

    now = eat.now()
    now.column += 2
    now.offset += 2

    return eat(value.slice(0, index))({
      type: 'footnote',
      children: self.tokenizeInline(value.slice(contentStart, contentEnd), now)
    })
  }

  // Do not allow `![^` or `[^` as a normal reference, do pass all other values
  // through.
  function reference(eat, value, silent) {
    var index = 0
    if (value.charCodeAt(index) === exclamationMark) index++
    if (value.charCodeAt(index) !== leftSquareBracket) return
    if (value.charCodeAt(index + 1) === caret) return
    return originalReference.call(this, eat, value, silent)
  }

  // Do not allow `[^` as a normal definition, do pass all other values through.
  function definition(eat, value, silent) {
    var index = 0
    var code = value.charCodeAt(index)
    while (code === space || code === tab) code = value.charCodeAt(++index)
    if (code !== leftSquareBracket) return
    if (value.charCodeAt(index + 1) === caret) return
    return originalDefinition.call(this, eat, value, silent)
  }

  function locateFootnoteCall(value, from) {
    return value.indexOf('[', from)
  }

  function locateFootnote(value, from) {
    return value.indexOf('^[', from)
  }
}

function attachCompiler(compiler) {
  var serializers = compiler.prototype.visitors
  var indent = '    '

  serializers.footnote = footnote
  serializers.footnoteReference = footnoteReference
  serializers.footnoteDefinition = footnoteDefinition

  function footnote(node) {
    return '^[' + this.all(node).join('') + ']'
  }

  function footnoteReference(node) {
    return '[^' + (node.label || node.identifier) + ']'
  }

  function footnoteDefinition(node) {
    var lines = this.all(node).join('\n\n').split('\n')
    var index = 0
    var length = lines.length
    var line

    // Indent each line, except the first, that is not empty.
    while (++index < length) {
      line = lines[index]
      if (line === '') continue
      lines[index] = indent + line
    }

    return '[^' + (node.label || node.identifier) + ']: ' + lines.join('\n')
  }
}

function before(list, before, value) {
  list.splice(list.indexOf(before), 0, value)
}

// Mimics <https://github.com/remarkjs/remark/blob/b4c993e/packages/remark-parse/lib/util/interrupt.js>,
// but simplified for our needs.
function interrupt(list, tokenizers, ctx, parameters) {
  var length = list.length
  var index = -1

  while (++index < length) {
    if (tokenizers[list[index][0]].apply(ctx, parameters)) {
      return true
    }
  }

  return false
}
