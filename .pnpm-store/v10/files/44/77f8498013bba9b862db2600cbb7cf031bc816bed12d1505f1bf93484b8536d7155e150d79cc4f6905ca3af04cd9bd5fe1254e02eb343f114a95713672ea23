'use strict'
const { sep: DEFAULT_SEPARATOR } = require('path')

const determineSeparator = paths => {
  for (const path of paths) {
    const match = /(\/|\\)/.exec(path)
    if (match !== null) return match[0]
  }

  return DEFAULT_SEPARATOR
}

module.exports = function commonPathPrefix (paths, sep = determineSeparator(paths)) {
  const [first = '', ...remaining] = paths
  if (first === '' || remaining.length === 0) return ''

  const parts = first.split(sep)

  let endOfPrefix = parts.length
  for (const path of remaining) {
    const compare = path.split(sep)
    for (let i = 0; i < endOfPrefix; i++) {
      if (compare[i] !== parts[i]) {
        endOfPrefix = i
      }
    }

    if (endOfPrefix === 0) return ''
  }

  const prefix = parts.slice(0, endOfPrefix).join(sep)
  return prefix.endsWith(sep) ? prefix : prefix + sep
}
