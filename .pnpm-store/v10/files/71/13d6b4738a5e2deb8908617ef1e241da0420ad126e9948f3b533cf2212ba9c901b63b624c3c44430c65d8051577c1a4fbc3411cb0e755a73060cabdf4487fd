const svgTagRenderer = require('./svg-tag')

exports.render = svgTagRenderer.render

exports.renderToFile = function renderToFile (path, qrData, options, cb) {
  if (typeof cb === 'undefined') {
    cb = options
    options = undefined
  }

  const fs = require('fs')
  const svgTag = exports.render(qrData, options)

  const xmlStr = '<?xml version="1.0" encoding="utf-8"?>' +
    '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">' +
    svgTag

  fs.writeFile(path, xmlStr, cb)
}
