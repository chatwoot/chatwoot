"use strict"

module.exports = function getMode(pluginSettings, filenameOrOptions) {
  const filename =
    typeof filenameOrOptions === "object"
      ? filenameOrOptions.filename
      : filenameOrOptions

  if (!filename) {
    return
  }
  if (pluginSettings.htmlExtensions.some(hasExtension)) {
    return "html"
  }
  if (pluginSettings.xmlExtensions.some(hasExtension)) {
    return "xml"
  }

  function hasExtension(extension) {
    if (!extension.startsWith(".")) {
      extension = `.${extension}`
    }
    return filename.endsWith(extension)
  }
}
