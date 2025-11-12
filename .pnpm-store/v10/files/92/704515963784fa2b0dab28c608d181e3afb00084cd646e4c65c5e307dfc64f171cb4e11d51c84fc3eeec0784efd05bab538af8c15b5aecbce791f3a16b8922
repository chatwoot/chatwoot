export function indent(lines: string[], count = 1) {
  return lines.map(line => `${'  '.repeat(count)}${line}`)
}

export function unindent(code: string) {
  const lines = code.split('\n')
  let indentLevel = -1
  let indentText: string
  const linesToAnalyze = lines.filter(line => line.trim().length > 0)
  for (const line of linesToAnalyze) {
    const match = /^\s*/.exec(line)
    if (match && (indentLevel === -1 || indentLevel > match[0].length)) {
      indentLevel = match[0].length
      indentText = match[0]
    }
  }
  const result: string[] = []
  for (const line of lines) {
    result.push(line.replace(indentText, ''))
  }
  return result.join('\n').trim()
}

interface AutoBuildingOject {
  key: string
  cache: Record<string | symbol, AutoBuildingOject>
  target: any
  proxy: any
}

export function createAutoBuildingObject(format?: (key: string) => string, specialKeysHandler?: (target: any, p: string | symbol) => (() => unknown) | null, key = '', depth = 0): AutoBuildingOject {
  const cache: Record<string | symbol, AutoBuildingOject> = {}
  if (depth > 32) return { key, cache, target: {}, proxy: () => key }
  const target: any = () => {
    const k = `${key}()`
    return format ? format(k) : k
  }
  const proxy = new Proxy(target, {
    get(_, p) {
      if (p === '__autoBuildingObject') {
        return true
      }
      if (p === '__autoBuildingObjectGetKey') {
        return key
      }
      if (specialKeysHandler) {
        const fn = specialKeysHandler(target, p)
        if (fn) {
          return fn()
        }
      }
      if (p === 'toString') {
        const k = `${key}.toString()`
        return () => format ? format(k) : k
      }
      if (p === Symbol.toPrimitive) {
        return () => format ? format(key) : key
      }
      if (!cache[p]) {
        const childKey = key ? `${key}.${p.toString()}` : p.toString()
        const child = createAutoBuildingObject(format, specialKeysHandler, childKey, depth + 1)
        cache[p] = { key: childKey, ...child }
      }
      return cache[p].proxy
    },
    apply(_, thisArg, args) {
      const k = `${key}(${args.join(', ')})`
      return format ? format(k) : k
    },
  })
  return {
    key,
    cache,
    target,
    proxy,
  }
}
