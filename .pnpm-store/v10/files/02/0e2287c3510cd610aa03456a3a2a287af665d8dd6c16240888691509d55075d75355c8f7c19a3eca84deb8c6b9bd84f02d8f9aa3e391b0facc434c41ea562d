import { embeddedWriteKey } from './embedded-write-key'

const analyticsScriptRegex =
  /(https:\/\/.*)\/analytics\.js\/v1\/(?:.*?)\/(?:platform|analytics.*)?/
const getCDNUrlFromScriptTag = (): string | undefined => {
  let cdn: string | undefined
  const scripts = Array.prototype.slice.call(
    document.querySelectorAll('script')
  )
  scripts.forEach((s) => {
    const src = s.getAttribute('src') ?? ''
    const result = analyticsScriptRegex.exec(src)

    if (result && result[1]) {
      cdn = result[1]
    }
  })
  return cdn
}

let _globalCDN: string | undefined // set globalCDN as in-memory singleton
const getGlobalCDNUrl = (): string | undefined => {
  const result = _globalCDN ?? window.analytics?._cdn
  return result
}

export const setGlobalCDNUrl = (cdn: string) => {
  if (window.analytics) {
    window.analytics._cdn = cdn
  }
  _globalCDN = cdn
}

export const getCDN = (): string => {
  const globalCdnUrl = getGlobalCDNUrl()

  if (globalCdnUrl) return globalCdnUrl

  const cdnFromScriptTag = getCDNUrlFromScriptTag()

  if (cdnFromScriptTag) {
    return cdnFromScriptTag
  } else {
    // it's possible that the CDN is not found in the page because:
    // - the script is loaded through a proxy
    // - the script is removed after execution
    // in this case, we fall back to the default Segment CDN
    return `https://cdn.june.so`
  }
}

export const getNextIntegrationsURL = () => {
  const cdn = getCDN()
  return `${cdn}/next-integrations`
}

/**
 * Replaces the CDN URL in the script tag with the one from Analytics.js 1.0
 *
 * @returns the path to Analytics JS 1.0
 **/
export function getLegacyAJSPath(): string {
  const writeKey = embeddedWriteKey() ?? window.analytics._writeKey

  const scripts = Array.prototype.slice.call(
    document.querySelectorAll('script')
  )
  let path: string | undefined = undefined

  for (const s of scripts) {
    const src = s.getAttribute('src') ?? ''
    const result = analyticsScriptRegex.exec(src)

    if (result && result[1]) {
      path = src
      break
    }
  }

  if (path) {
    return path.replace('analytics.min.js', 'analytics.classic.js')
  }

  return `https://cdn.june.so/analytics.js/v1/${writeKey}/analytics.classic.js`
}
