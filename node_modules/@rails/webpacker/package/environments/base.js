/* eslint global-require: 0 */
/* eslint import/no-dynamic-require: 0 */

const {
  basename, dirname, join, relative, resolve
} = require('path')
const { sync } = require('glob')
const extname = require('path-complete-extname')

const webpack = require('webpack')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const WebpackAssetsManifest = require('webpack-assets-manifest')
const CaseSensitivePathsPlugin = require('case-sensitive-paths-webpack-plugin')
const PnpWebpackPlugin = require('pnp-webpack-plugin')

const { isNotObject, prettyPrint } = require('../utils/helpers')
const deepMerge = require('../utils/deep_merge')

const { ConfigList, ConfigObject } = require('../config_types')
const rules = require('../rules')
const config = require('../config')

const getLoaderList = () => {
  const result = new ConfigList()
  Object.keys(rules).forEach((key) => result.append(key, rules[key]))
  return result
}

const getPluginList = () => {
  const result = new ConfigList()
  result.append(
    'Environment',
    new webpack.EnvironmentPlugin(process.env)
  )
  result.append('CaseSensitivePaths', new CaseSensitivePathsPlugin())
  result.append(
    'MiniCssExtract',
    new MiniCssExtractPlugin({
      filename: 'css/[name]-[contenthash:8].css',
      chunkFilename: 'css/[name]-[contenthash:8].chunk.css'
    })
  )
  result.append(
    'Manifest',
    new WebpackAssetsManifest({
      entrypoints: true,
      writeToDisk: true,
      publicPath: config.publicPathWithoutCDN
    })
  )
  return result
}

const getExtensionsGlob = () => {
  const { extensions } = config
  return extensions.length === 1 ? `**/*${extensions[0]}` : `**/*{${extensions.join(',')}}`
}

const getEntryObject = () => {
  const result = new ConfigObject()
  const glob = getExtensionsGlob()
  const rootPath = join(config.source_path, config.source_entry_path)
  const paths = sync(join(rootPath, glob))
  paths.forEach((path) => {
    const namespace = relative(join(rootPath), dirname(path))
    const name = join(namespace, basename(path, extname(path)))
    let assetPaths = resolve(path)

    // Allows for multiple filetypes per entry (https://webpack.js.org/guides/entry-advanced/)
    // Transforms the config object value to an array with all values under the same name
    let previousPaths = result.get(name)
    if (previousPaths) {
      previousPaths = Array.isArray(previousPaths) ? previousPaths : [previousPaths]
      previousPaths.push(assetPaths)
      assetPaths = previousPaths
    }

    result.set(name, assetPaths)
  })
  return result
}

const getModulePaths = () => {
  const result = new ConfigList()
  result.append('source', resolve(config.source_path))
  if (config.additional_paths) {
    config.additional_paths.forEach((path) => result.append(path, resolve(path)))
  }
  result.append('node_modules', 'node_modules')
  return result
}

const getBaseConfig = () => new ConfigObject({
  mode: 'production',
  output: {
    filename: 'js/[name]-[contenthash].js',
    chunkFilename: 'js/[name]-[contenthash].chunk.js',
    hotUpdateChunkFilename: 'js/[id]-[hash].hot-update.js',
    path: config.outputPath,
    publicPath: config.publicPath
  },

  resolve: {
    extensions: config.extensions,
    plugins: [PnpWebpackPlugin]
  },

  resolveLoader: {
    modules: ['node_modules'],
    plugins: [PnpWebpackPlugin.moduleLoader(module)]
  },

  node: {
    dgram: 'empty',
    fs: 'empty',
    net: 'empty',
    tls: 'empty',
    child_process: 'empty'
  }
})

module.exports = class Base {
  constructor() {
    this.loaders = getLoaderList()
    this.plugins = getPluginList()
    this.config = getBaseConfig()
    this.entry = getEntryObject()
    this.resolvedModules = getModulePaths()
  }

  splitChunks(callback = null) {
    let appConfig = {}
    const defaultConfig = {
      optimization: {
        // Split vendor and common chunks
        // https://twitter.com/wSokra/status/969633336732905474
        splitChunks: {
          chunks: 'all',
          name: true
        },
        // Separate runtime chunk to enable long term caching
        // https://twitter.com/wSokra/status/969679223278505985
        runtimeChunk: true
      }
    }

    if (callback) {
      appConfig = callback(defaultConfig)
      if (isNotObject(appConfig)) {
        throw new Error(`
          ${prettyPrint(appConfig)} is not a valid splitChunks configuration.
          See https://webpack.js.org/plugins/split-chunks-plugin/#configuration
        `)
      }
    }

    return this.config.merge(deepMerge(defaultConfig, appConfig))
  }

  toWebpackConfig() {
    return this.config.merge({
      entry: this.entry.toObject(),

      module: {
        strictExportPresence: true,
        rules: this.loaders.values()
      },

      plugins: this.plugins.values(),

      resolve: {
        modules: this.resolvedModules.values()
      }
    })
  }
}
