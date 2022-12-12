const ensureRequire = require('../ensure-require.js')
const throwError = require('../utils').throwError
const getBabelOptions = require('../utils').getBabelOptions

module.exports = {
  process(src, filename, config) {
    ensureRequire('coffee', ['coffeescript'])
    const coffee = require('coffeescript')
    const babelOptions = getBabelOptions(filename)
    let compiled
    try {
      compiled = coffee.compile(src, {
        filename,
        bare: true,
        sourceMap: true,
        transpile: babelOptions
      })
    } catch (err) {
      throwError(err)
    }
    return {
      code: compiled.js,
      map: compiled.v3SourceMap
    }
  }
}
