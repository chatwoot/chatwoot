"use strict"

const oneLine = require("./utils").oneLine

const defaultHTMLExtensions = [
  ".erb",
  ".handlebars",
  ".hbs",
  ".htm",
  ".html",
  ".mustache",
  ".nunjucks",
  ".php",
  ".tag",
  ".riot",
  ".twig",
  ".we",
]

const defaultXMLExtensions = [".xhtml", ".xml"]

function filterOut(array, excludeArray) {
  if (!excludeArray) return array
  return array.filter((item) => excludeArray.indexOf(item) < 0)
}

function compileRegExp(re) {
  const tokens = re.split("/")
  if (tokens.shift()) {
    // Ignore first token
    throw new Error(`Invalid regexp: ${re}`)
  }
  const flags = tokens.pop()
  return new RegExp(tokens.join("/"), flags)
}

function getSetting(settings, name) {
  if (typeof settings.html === "object" && name in settings.html) {
    return settings.html[name]
  }
  return settings[`html/${name}`]
}

function getSettings(settings) {
  const htmlExtensions =
    getSetting(settings, "html-extensions") ||
    filterOut(defaultHTMLExtensions, getSetting(settings, "xml-extensions"))

  const xmlExtensions =
    getSetting(settings, "xml-extensions") ||
    filterOut(defaultXMLExtensions, getSetting(settings, "html-extensions"))

  const javaScriptTagNames = getSetting(settings, "javascript-tag-names") || [
    "script",
  ]

  let reportBadIndent
  switch (getSetting(settings, "report-bad-indent")) {
    case undefined:
    case false:
    case 0:
    case "off":
      reportBadIndent = 0
      break
    case true:
    case 1:
    case "warn":
      reportBadIndent = 1
      break
    case 2:
    case "error":
      reportBadIndent = 2
      break
    default:
      throw new Error(
        oneLine`
        Invalid value for html/report-bad-indent,
        expected one of 0, 1, 2, "off", "warn" or "error"
      `
      )
  }

  const parsedIndent = /^(\+)?(tab|\d+)$/.exec(getSetting(settings, "indent"))
  const indent = parsedIndent && {
    relative: parsedIndent[1] === "+",
    spaces: parsedIndent[2] === "tab" ? "\t" : " ".repeat(parsedIndent[2]),
  }

  const rawJavaScriptMIMETypes = getSetting(settings, "javascript-mime-types")
  const javaScriptMIMETypes = rawJavaScriptMIMETypes
    ? (Array.isArray(rawJavaScriptMIMETypes)
        ? rawJavaScriptMIMETypes
        : [rawJavaScriptMIMETypes]
      ).map((s) => (s.startsWith("/") ? compileRegExp(s) : s))
    : [
        /^(application|text)\/(x-)?(javascript|babel|ecmascript-6)$/i,
        /^module$/i,
      ]

  function isJavaScriptMIMEType(type) {
    return javaScriptMIMETypes.some((o) =>
      typeof o === "string" ? type === o : o.test(type)
    )
  }

  return {
    htmlExtensions,
    xmlExtensions,
    javaScriptTagNames,
    indent,
    reportBadIndent,
    isJavaScriptMIMEType,
  }
}

module.exports = {
  getSettings,
}
