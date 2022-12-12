module.exports = {
  entry: "./plugins/index.js",
  mode: "development",
  output: {
    library: "videoPlugins",
    libraryTarget: "umd",
    path: __dirname + "/dist",
    filename: "index.js"
  },
  devServer: {
    contentBase: "./dist"
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["babel-preset-env"]
          }
        }
      }
    ]
  }
};
