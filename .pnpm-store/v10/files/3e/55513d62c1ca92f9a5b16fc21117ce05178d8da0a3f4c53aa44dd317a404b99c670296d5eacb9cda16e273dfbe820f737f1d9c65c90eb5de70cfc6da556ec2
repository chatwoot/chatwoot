const KEY_ESCAPE_REG = /[\s-.:|#@$£*%]/
const MAX_SINGLE_LINE_ARRAY_LENGTH = 3

interface Line {
  spaces: number
  line: string
}

export function serializeJs(value: any): string {
  const seen = new Set()

  if (value === undefined) {
    return 'undefined'
  }
  if (value === null) {
    return 'null'
  }
  if (typeof value === 'string') {
    return `'${value}'`
  }
  if (typeof value === 'boolean') {
    return value ? 'true' : 'false'
  }
  if (Array.isArray(value)) {
    return printLines(arrayToSourceLines(value, seen))
  }
  if (typeof value === 'object') {
    return printLines(objectToSourceLines(value, seen))
  }
  if (value?.__autoBuildingObject) {
    return value
  }
  if (typeof value === 'function' && value.name) {
    return value.name
  }
  return value.toString()
}

function printLines(lines: Line[]) {
  return lines.map(line => '  '.repeat(line.spaces) + line.line).join('\n')
}

function objectToSourceLines(object, seen: Set<unknown>, indentCount = 0) {
  if (seen.has(object)) {
    object = {}
  }
  else {
    seen.add(object)
  }

  return createLines(indentCount, (lines) => {
    lines.push('{')
    lines.push(...createLines(1, (lines) => {
      for (const key in object) {
        const value = object[key]

        let printedKey = key
        if (KEY_ESCAPE_REG.test(key)) {
          printedKey = `'${printedKey}'`
        }

        addLinesFromValue(lines, value, `${printedKey}: `, ',', seen)
      }
    }))
    lines.push('}')
  })
}

function arrayToSourceLines(array: any[], seen: Set<unknown>, indentCount = 0): Array<Line> {
  if (seen.has(array)) {
    array = []
  }
  else {
    seen.add(array)
  }

  return createLines(indentCount, (lines) => {
    const contentLines = createLines(1, (lines) => {
      for (const value of array) {
        addLinesFromValue(lines, value, '', ',', seen)
      }
    })
    if (contentLines.length === 0) {
      lines.push('[]')
    }
    else if (contentLines.length <= MAX_SINGLE_LINE_ARRAY_LENGTH && !contentLines.some(line => line.spaces > 1)) {
      const [first] = contentLines
      first.line = contentLines.map(({ line }) => line.substring(0, line.length - 1)).join(', ')
      first.line = `[${first.line}]`
      first.spaces--
      lines.push(first)
    }
    else {
      lines.push('[', ...contentLines, ']')
    }
  })
}

function createLines(indentCount: number, handler: (lines: any[]) => unknown): Array<Line> {
  const lines: any[] = []
  handler(lines)
  return lines.map((line) => {
    if (line.spaces != null) {
      line.spaces += indentCount
      return line
    }
    return { spaces: indentCount, line }
  })
}

function addLinesFromValue(lines: Line[], value, before, after, seen) {
  let result
  if (Array.isArray(value)) {
    lines.push(...wrap(arrayToSourceLines(value, seen), before, after))
    return
  }
  else if (value && typeof value === 'object') {
    lines.push(...wrap(objectToSourceLines(value, seen), before, after))
    return
  }
  else if (typeof value === 'string') {
    result = value.includes('\'') ? `\`${value}\`` : `'${value}'`
  }
  else if (typeof value === 'undefined') {
    result = 'undefined'
  }
  else if (value === null) {
    result = 'null'
  }
  else if (typeof value === 'boolean') {
    result = value ? 'true' : 'false'
  }
  else {
    result = value
  }
  lines.push(before + result + after)
}

function wrap(lines: Line[], before: string, after: string) {
  lines[0].line = before + lines[0].line
  lines[lines.length - 1].line += after
  return lines
}
