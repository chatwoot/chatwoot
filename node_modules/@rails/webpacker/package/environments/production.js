const TerserPlugin = require('terser-webpack-plugin')
const CompressionPlugin = require('compression-webpack-plugin')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin')
const safePostCssParser = require('postcss-safe-parser')
const Base = require('./base')

module.exports = class extends Base {
  constructor() {
    super()

    this.plugins.append(
      'Compression',
      new CompressionPlugin({
        filename: '[path].gz[query]',
        algorithm: 'gzip',
        test: /\.(js|css|html|json|ico|svg|eot|otf|ttf|map)$/
      })
    )

    if ('brotli' in process.versions) {
      this.plugins.append(
        'Compression Brotli',
        new CompressionPlugin({
          filename: '[path].br[query]',
          algorithm: 'brotliCompress',
          test: /\.(js|css|html|json|ico|svg|eot|otf|ttf|map)$/
        })
      )
    }

    this.plugins.append(
      'OptimizeCSSAssets',
      new OptimizeCSSAssetsPlugin({
        parser: safePostCssParser,
        map: {
          inline: false,
          annotation: true
        }
      })
    )

    this.config.merge({
      devtool: 'source-map',
      stats: 'normal',
      bail: true,
      optimization: {
        minimizer: [
          new TerserPlugin({
            parallel: Number.parseInt(process.env.WEBPACKER_PARALLEL, 10) || true,
            cache: true,
            sourceMap: true,
            terserOptions: {
              parse: {
                // Let terser parse ecma 8 code but always output
                // ES5 compliant code for older browsers
                ecma: 8
              },
              compress: {
                ecma: 5,
                warnings: false,
                comparisons: false
              },
              mangle: {
                safari10: true
              },
              output: {
                ecma: 5,
                comments: false,
                ascii_only: true
              }
            }
          })
        ]
      }
    })
  }
}
