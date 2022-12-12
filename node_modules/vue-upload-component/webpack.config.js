const path              = require('path')
const merge             = require('webpack-merge')
const webpack           = require('webpack')

const packageInfo       = require('./package')

const bodyParser       = require('webpack-body-parser')
const chunkUpload      = require('./src/utils/chunkUpload')
const { VueLoaderPlugin } =  require('vue-loader')

process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const isDev = process.env.NODE_ENV === 'development'

function baseConfig() {
  let config = {
    mode: process.env.NODE_ENV === 'development' ? 'development' : 'production',
    output: {
      path: path.join(__dirname, 'dist'),
      publicPath: '/dist',
      filename: '[name].js',
      chunkFilename: '[chunkhash:8].[name].chunk.js',
    },

    resolve: {
      modules: [
        path.join(__dirname, 'node_modules'),
      ],

      alias: {
        'vue-upload-component': path.join(__dirname, 'src'),
      },

      extensions: [
        '.js',
        '.jsx',
        '.json',
        '.vue',
        '.md',
      ],
    },


    externals: {
      vue: 'Vue',
      vuex: 'Vuex',
      'vue-router': 'VueRouter',
      'vue-i18n': 'VueI18n',
      'marked': 'marked',
      'highlight.js': 'hljs',
      'cropperjs': 'Cropper',
      '@xkeshi/image-compressor': 'ImageCompressor',
    },


    module: {
      rules: [
        {
          test: /\.jsx?$/,
          use: [
            {
              loader: 'babel-loader',
              options: {
                presets: [
                  [
                    'env',
                    {
                      modules: false
                    }
                  ],
                  'stage-0',
                ],
                plugins: [
                  [
                    'transform-runtime',
                    {
                      helpers: false,
                      polyfill: false,
                      regenerator: true,
                      moduleName: 'babel-runtime'
                    }
                  ]
                ],
                cacheDirectory: isDev
              },
            },
            {
              loader: 'eslint-loader',
            },
          ],
        },
        {
          test: /\.(md|txt)$/,
          use: [
            {
              loader: 'raw-loader',
            },
          ]
        },
        {
          test: /\.css$/,
          use: [
            {
              loader: 'vue-style-loader',
            },
            {
              loader: 'css-loader',
              options: {
                minimize: !isDev,
              },
            },
          ]
        },
        {
          test: /\.vue$/,
          use: [
            {
              loader: 'vue-loader',
              options: {
                preserveWhitespace: false,
                cssModules: {
                  localIdentName: '[hash:base64:8]',
                  camelCase: true,
                },
              },
            },
          ],
        },
        /*
        {
          test: /\.vue$/,
          use: [
            {
              loader: 'vue-loader',
              options: {
                preserveWhitespace: false,
                loaders: {
                  js: [
                    {
                      loader: 'babel-loader',
                      options: {
                        presets: [
                          [
                            'env',
                            {
                              modules: false
                            }
                          ],
                          'stage-0'
                        ],
                        plugins: [
                          [
                            'transform-runtime',
                            {
                              helpers: false,
                              polyfill: false,
                              regenerator: true,
                              moduleName: 'babel-runtime'
                            }
                          ]
                        ],
                        cacheDirectory: isDev
                      }
                    },
                  ],
                }
              },
            },
            {
              loader: 'eslint-loader',
            },
          ]
        }
        */
      ]
    },

    plugins: [
      new webpack.BannerPlugin(`Name: ${packageInfo.name}\nVersion: ${packageInfo.version}\nAuthor: ${packageInfo.author}`),
      new VueLoaderPlugin(),
    ],
    devtool: isDev ? 'eval-source-map' : 'source-map'
  }

  if (isDev) {
    config.plugins.push(new webpack.HotModuleReplacementPlugin())
  }
  return config
}



module.exports = merge(baseConfig(), {
  entry: {
    index: [
      path.join(__dirname, 'docs/index.js'),
    ],
  },

  output: {
    path: path.join(__dirname, 'docs/dist'),
  },

  devServer: {
    before(app) {
      let id = 1000000
      let put = function (req, res) {
        setTimeout(function () {
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
      let del = function (req, res) {
        res.json({ success: true })
      }

      // Chunk upload
      app.post('/upload/chunk', bodyParser.json(), chunkUpload)

      app.post('/upload/post', put)
      app.put('/upload/put', put)
      app.post('/upload/delete', del)
      app.delete('/upload/delete', del)
    },
    // host: '0.0.0.0',
    hot: true,
    contentBase: path.join(__dirname, 'docs'),
    clientLogLevel: 'error',
    noInfo: true,
    publicPath: '/dist',
    inline: true,
    historyApiFallback: true,
    overlay: {
      warnings: true,
      errors: true
    },
    // host: '172.16.23.1'
  },
})
