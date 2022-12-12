var postcss = require('postcss')

module.exports = postcss.plugin('postcss-replace-overflow-wrap', function (opts) {
  opts = opts || {}
  var method = opts.method || 'replace'

  return function (css) {
    css.walkDecls('overflow-wrap', function (decl) {
      decl.cloneBefore({ prop: 'word-wrap' })
      if (method === 'replace') {
        decl.remove()
      }
    })
  }
})
