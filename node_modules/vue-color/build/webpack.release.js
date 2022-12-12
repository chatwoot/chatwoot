var path = require('path')
var vueLoaderConfig = require('./vue-loader.conf')

function resolve (dir) {
  return path.join(__dirname, '..', dir)
}

module.exports = {
  entry: {
    'vue-color': './src/index.js'
  },
  output: {
    filename: './dist/[name].js',
    library: 'VueColor',
    libraryTarget: 'umd'
  },
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader',
        options: vueLoaderConfig
      },
      {
        test: /\.js$/,
        loader: 'babel-loader',
        include: [resolve('src')],
        exclude: /node_modules/
      }
    ]
  },

  node: {
    // prevent webpack from injecting an global polyfill that includes Function(return this) and eval(this)
    global: false
  }
}
