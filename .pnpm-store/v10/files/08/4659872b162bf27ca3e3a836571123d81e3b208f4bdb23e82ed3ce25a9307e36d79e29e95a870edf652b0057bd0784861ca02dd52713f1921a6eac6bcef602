import cookie from 'js-cookie'

/**
 * Levels returns all levels of the given url.
 *
 * @param {string} url
 * @return {Array}
 * @api public
 */
function levels(url: URL): string[] {
  const host = url.hostname
  const parts = host.split('.')
  const last = parts[parts.length - 1]
  const levels: string[] = []

  // Ip address.
  if (parts.length === 4 && parseInt(last, 10) > 0) {
    return levels
  }

  // Localhost.
  if (parts.length <= 1) {
    return levels
  }

  // Create levels.
  for (let i = parts.length - 2; i >= 0; --i) {
    levels.push(parts.slice(i).join('.'))
  }

  return levels
}

function parseUrl(url: string): URL | undefined {
  try {
    return new URL(url)
  } catch {
    return
  }
}

export function tld(url: string): string | undefined {
  const parsedUrl = parseUrl(url)
  if (!parsedUrl) return

  const lvls = levels(parsedUrl)

  // Lookup the real top level one.
  for (let i = 0; i < lvls.length; ++i) {
    const cname = '__tld__'
    const domain = lvls[i]
    const opts = { domain: '.' + domain }

    try {
      // cookie access throw an error if the library is ran inside a sandboxed environment (e.g. sandboxed iframe)
      cookie.set(cname, '1', opts)
      if (cookie.get(cname)) {
        cookie.remove(cname, opts)
        return domain
      }
    } catch (_) {
      return
    }
  }
}
