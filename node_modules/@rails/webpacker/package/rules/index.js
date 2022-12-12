const babel = require('./babel')
const file = require('./file')
const css = require('./css')
const sass = require('./sass')
const moduleCss = require('./module.css')
const moduleSass = require('./module.sass')
const nodeModules = require('./node_modules')

// Webpack loaders are processed in reverse order
// https://webpack.js.org/concepts/loaders/#loader-features
// Lastly, process static files using file loader
module.exports = {
  file,
  css,
  sass,
  moduleCss,
  moduleSass,
  nodeModules,
  babel
}
