'use strict'
var refractorT4Templating = require('./t4-templating.js')
var refractorVbnet = require('./vbnet.js')
module.exports = t4Vb
t4Vb.displayName = 't4Vb'
t4Vb.aliases = []
function t4Vb(Prism) {
  Prism.register(refractorT4Templating)
  Prism.register(refractorVbnet)
  Prism.languages['t4-vb'] = Prism.languages['t4-templating'].createT4('vbnet')
}
