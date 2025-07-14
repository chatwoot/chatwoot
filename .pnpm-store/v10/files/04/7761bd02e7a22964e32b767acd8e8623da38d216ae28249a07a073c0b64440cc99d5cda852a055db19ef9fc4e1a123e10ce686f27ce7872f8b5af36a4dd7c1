module.exports = {
  entry: "./plugins/index.js",
  mode: "production",
  output: {
    filename: 'index.umd.js',
    library: 'analyticsVideoPlugins',
    libraryTarget: 'umd',
    path: __dirname + "/dist",
  },
  optimization: {
    minimize: true
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "babel-loader"
        }
      }
    ]
  }
};
