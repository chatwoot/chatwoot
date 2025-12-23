/* eslint-env node */

const path = require("path");

module.exports = {
  mode: "production",
  entry: {
    index: "./src/index.ts",
  },
  devtool: "source-map",
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "dist"),
  },
  module: {
    rules: [
      {
        test: /\.ts$/,
        use: [{ loader: "babel-loader" }, { loader: "ts-loader" }],
        exclude: /node_modules/,
      },
      {
        test: /\.js$/,
        use: [{ loader: "babel-loader" }],
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    alias: { "~/": path.resolve(__dirname, "src/") },
    extensions: [".tsx", ".ts", ".js"],
  },
};
