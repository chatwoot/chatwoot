const { nodeEnv } = require('../env')

// Compile standard ES features for JS in node_modules with Babel.
//   Regex details for exclude: https://regex101.com/r/SKPnnv/1
module.exports = {
  test: /\.(js|mjs)$/,
  include: /node_modules/,
  exclude: /(?:@?babel(?:\/|\\{1,2}|-).+)|regenerator-runtime|core-js|^webpack$|^webpack-assets-manifest$|^webpack-cli$|^webpack-sources$|^@rails\/webpacker$/,
  use: [
    {
      loader: 'babel-loader',
      options: {
        babelrc: false,
        presets: [['@babel/preset-env', { modules: false }]],
        cacheDirectory: true,
        cacheCompression: nodeEnv === 'production',
        compact: false,
        sourceMaps: false
      }
    }
  ]
}
