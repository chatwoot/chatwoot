'use strict'
var refractorT4Templating = require('./t4-templating.js')
var refractorCsharp = require('./csharp.js')
module.exports = t4Cs
t4Cs.displayName = 't4Cs'
t4Cs.aliases = []
function t4Cs(Prism) {
  Prism.register(refractorT4Templating)
  Prism.register(refractorCsharp)
  Prism.languages.t4 = Prism.languages['t4-cs'] =
    Prism.languages['t4-templating'].createT4('csharp')
}
