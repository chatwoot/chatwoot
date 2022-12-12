const webpack = require('webpack')
const Base = require('./base')
const devServer = require('../dev_server')
const { outputPath: contentBase, publicPath } = require('../config')

module.exports = class extends Base {
  constructor() {
    super()

    this.config.merge({
      mode: 'development',
      devtool: 'cheap-module-source-map'
    })

    if (process.env.WEBPACK_DEV_SERVER
        && process.env.WEBPACK_DEV_SERVER !== 'undefined') {
      if (devServer.hmr) {
        this.plugins.append('HotModuleReplacement', new webpack.HotModuleReplacementPlugin())
        this.config.output.filename = '[name]-[hash].js'
      }

      this.config.merge({
        devServer: {
          clientLogLevel: 'none',
          compress: devServer.compress,
          quiet: devServer.quiet,
          disableHostCheck: devServer.disable_host_check,
          host: devServer.host,
          port: devServer.port,
          https: devServer.https,
          hot: devServer.hmr,
          contentBase,
          inline: devServer.inline,
          useLocalIp: devServer.use_local_ip,
          public: devServer.public,
          publicPath,
          historyApiFallback: {
            disableDotRule: true
          },
          headers: devServer.headers,
          overlay: devServer.overlay,
          stats: {
            entrypoints: false,
            errorDetails: true,
            modules: false,
            moduleTrace: false
          },
          watchOptions: devServer.watch_options
        }
      })
    }
  }
}
