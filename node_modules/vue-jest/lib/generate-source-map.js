const path = require('path')
const sourceMap = require('source-map')
const splitRE = /\r?\n/g

module.exports = function generateSourceMap(
  scriptResult,
  src,
  filename,
  renderFnStartLine,
  renderFnEndLine,
  templateLine
) {
  const file = path.basename(filename)
  const map = new sourceMap.SourceMapGenerator()

  const scriptFromExternalSrc = scriptResult && scriptResult.externalSrc

  // If script uses external file for content (using the src attribute) then
  // map result to this file, instead of original.
  const srcContent = scriptFromExternalSrc ? scriptResult.externalSrc : src

  map.setSourceContent(file, srcContent)
  if (scriptResult) {
    let inputMapConsumer =
      scriptResult.map && new sourceMap.SourceMapConsumer(scriptResult.map)
    scriptResult.code.split(splitRE).forEach(function(line, index) {
      let ln = index + 1
      let originalLine = inputMapConsumer
        ? inputMapConsumer.originalPositionFor({ line: ln, column: 0 }).line
        : ln
      if (originalLine) {
        map.addMapping({
          source: file,
          generated: {
            line: ln,
            column: 0
          },
          original: {
            line: originalLine,
            column: 0
          }
        })
      }
    })
  }

  // If script is from external src then the source map will only show the
  // script section. We won't map the generated render function to this file,
  // because the coverage report would be confusing
  if (scriptFromExternalSrc) {
    return map
  }

  for (; renderFnStartLine < renderFnEndLine; renderFnStartLine++) {
    map.addMapping({
      source: file,
      generated: {
        line: renderFnStartLine,
        column: 0
      },
      original: {
        line: templateLine,
        column: 0
      }
    })
  }

  return map
}
