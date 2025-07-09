/* eslint @typescript-eslint/no-require-imports: 0 */

const fs = require('fs')
const path = require('path')
const webpack = require('webpack')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const CssMinimizerWebpackPlugin = require('css-minimizer-webpack-plugin');
const chunkUpload = require('./src/utils/chunkUpload')
const bodyParser = require('webpack-body-parser')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const packageInfo = require('./package.json')
const { VueLoaderPlugin } = require('vue-loader')
const isDev = process.env.NODE_ENV === 'development'
const ESLintPlugin = require('eslint-webpack-plugin');

const IsCssExtract = !isDev

if (!isDev) {
  let version = packageInfo.version.split('.');
  version[version.length - 1] = parseInt(version[version.length - 1], 10) + 1;
  packageInfo.version = version.join('.');
  fs.writeFileSync('./package.json', JSON.stringify(packageInfo, null, 2), { flags: 'utf8' })
}


module.exports = {
  mode: process.env.NODE_ENV,
  devtool: isDev ? 'eval-source-map' : 'source-map',

  entry: {
    docs: [
      path.join(__dirname, 'docs/entry.js'),
    ],
  },

  output: {
    path: __dirname,
    publicPath: './',
    filename: 'docs/dist/[name].js',
    chunkFilename: 'docs/dist/[chunkhash:8].[name].chunk.js',
  },

  resolve: {
    modules: [
      path.join(__dirname, 'node_modules'),
      path.join(__dirname, 'docs'),
    ],
    alias: {
      // "vue": "@vue/runtime-dom",
      "@": path.join(__dirname, 'src'),
      "@/": path.join(__dirname, 'src/'),
      'vue-upload-component': path.join(__dirname, isDev ? 'src' : 'dist/vue-upload-component.js'),
    },
    extensions: [
      '.js',
      '.ts',
      '.tsx',
      '.json',
      '.vue',
      '.md',
    ],
  },
  externals: {
    // vue: 'Vue',
    // vuex: 'Vuex',
    // 'vue-router': 'VueRouter',
    // 'vue-i18n': 'VueI18n',
    'marked': 'marked',
    'highlight.js': 'hljs',
    'cropperjs': 'Cropper',
    'crypto-js': 'CryptoJS',
    '@xkeshi/image-compressor': 'ImageCompressor',
  },

  // cache: false,
  devServer: {
    hot: true,
    liveReload: true,
    allowedHosts: "all",
    client: {
      logging: 'error',
      overlay: true,
    },


    setupMiddlewares(middlewares, devServer) {
      if (!devServer) {
        throw new Error('webpack-dev-server is not defined');
      }
      let id = 1000000
      let put = function(req, res) {
        setTimeout(function() {
          let rand = Math.random()
          if (rand <= 0.1) {
            res.status(500)
            res.json({ error: 'server', success: false })
          } else if (rand <= 0.25) {
            res.status(403)
            res.json({ error: 'failure', success: false })
          } else {
            res.json({ url: 'https://vuejs.org/images/logo.png?id=' + id, name: 'filename.ext', id: id++, success: true })
          }
        }, 200 + parseInt(Math.random() * 4000, 10))
      }
      let del = function(req, res) {
        res.json({ success: true })
      }

      // Chunk upload
      devServer.app.post('/upload/chunk', bodyParser.json(), chunkUpload)

      devServer.app.post('/upload/post', put)
      devServer.app.put('/upload/put', put)
      devServer.app.post('/upload/delete', del)
      devServer.app.delete('/upload/delete', del)

      return middlewares
    },
    host: '127.0.0.1',
    static: {
      directory: __dirname,
    },

    compress: true,

    devMiddleware: {
      index: true,
      mimeTypes: { phtml: 'text/html' },
      publicPath: '/',
      serverSideRender: true,
      writeToDisk: false,
    },


    // noInfo: true,
    historyApiFallback: true,
  },

  target: 'web',

  module: {
    rules: [{
        test: /\.vue$/,
        use: [{
          loader: 'vue-loader',
          options: {
            compilerOptions: {
              whitespace: 'condense',
              compatConfig: {
                FEATURE_ID_A: false,
                FEATURE_ID_B: false

              },
            },
            transpileOptions: {
              transforms: {
                dangerousTaggedTemplateString: true
              }
            },
          },
        }],
      },
      {
        test: /\.html?$/,
        use: [{
          loader: 'html-loader',
        }]
      },
      {
        test: /\.(js|jsx)$/,
        use: [{
          loader: 'babel-loader',
        }, ],
      },
      {
        test: /\.(md|txt)$/,
        use: [{
          loader: 'raw-loader',
        }, ]
      },
      {
        test: /\.tsx?$/,
        use: [{
          loader: 'ts-loader',
          options: {
            appendTsSuffixTo: [/\.(vue|tsx?)$/],
            transpileOnly: true,
          }
        }],
      },
      {
        test: /(\.css)$/,
        use: [{
            loader: 'style-loader',
          },
          {
            loader: "css-loader",
            options: {
              importLoaders: 1,
            },
          },
        ],
      },
    ]
  },


  plugins: [
    // new webpack.HotModuleReplacementPlugin(),
    new webpack.BannerPlugin(`Name: ${packageInfo.name}\nComponent URI: ${packageInfo.homepage}\nVersion: ${packageInfo.version}\nAuthor: ${packageInfo.author}\nLicense: ${packageInfo.license}\nDescription: ${packageInfo.description}`),
    new webpack.DefinePlugin({
      'process.version': JSON.stringify(packageInfo.version),
      __VUE_OPTIONS_API__: true,
      __VUE_PROD_DEVTOOLS__: true,
    }),


    // new MiniCssExtractPlugin({
    //   filename: 'assets/[name].css',
    //   chunkFilename: 'assets/[name].[id].css',
    // }),
    new ESLintPlugin(),
    new VueLoaderPlugin(),

    new CssMinimizerWebpackPlugin(),

    new HtmlWebpackPlugin({
      filename: 'index.html',
      template: path.join(__dirname, 'docs/index.template.html'),
      minify: {
        collapseWhitespace: true,
        collapseInlineTagWhitespace: true,
        removeComments: true,
        removeRedundantAttributes: true,
        removeScriptTypeAttributes: true,
        removeStyleLinkTypeAttributes: true,
        useShortDoctype: true,
        html5: true,
      },
      xhtml: true,
      inlineSource: '.(js|css)$',
    }),
  ],
};