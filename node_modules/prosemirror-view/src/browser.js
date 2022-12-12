const result = {}
export default result

if (typeof navigator != "undefined" && typeof document != "undefined") {
  const ie_edge = /Edge\/(\d+)/.exec(navigator.userAgent)
  const ie_upto10 = /MSIE \d/.test(navigator.userAgent)
  const ie_11up = /Trident\/(?:[7-9]|\d{2,})\..*rv:(\d+)/.exec(navigator.userAgent)

  result.mac = /Mac/.test(navigator.platform)
  let ie = result.ie = !!(ie_upto10 || ie_11up || ie_edge)
  result.ie_version = ie_upto10 ? document.documentMode || 6 : ie_11up ? +ie_11up[1] : ie_edge ? +ie_edge[1] : null
  result.gecko = !ie && /gecko\/(\d+)/i.test(navigator.userAgent)
  result.gecko_version = result.gecko && +(/Firefox\/(\d+)/.exec(navigator.userAgent) || [0, 0])[1]
  let chrome = !ie && /Chrome\/(\d+)/.exec(navigator.userAgent)
  result.chrome = !!chrome
  result.chrome_version = chrome && +chrome[1]
  // Is true for both iOS and iPadOS for convenience
  result.safari = !ie && /Apple Computer/.test(navigator.vendor)
  result.ios = result.safari && (/Mobile\/\w+/.test(navigator.userAgent) || navigator.maxTouchPoints > 2)
  result.android = /Android \d/.test(navigator.userAgent)
  result.webkit = "webkitFontSmoothing" in document.documentElement.style
  result.webkit_version = result.webkit && +(/\bAppleWebKit\/(\d+)/.exec(navigator.userAgent) || [0, 0])[1]
}
