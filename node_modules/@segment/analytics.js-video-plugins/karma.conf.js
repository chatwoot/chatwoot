const webpack = require("webpack");

module.exports = function(config) {
  config.set({
    frameworks: ["mocha", "sinon-chai"],
    files: ["https://player.vimeo.com/api/player.js", "plugins/**/*.test.js"],
    browsers: ["Chrome"],
    client: {
      mocha: {
        reporter: "html"
      }
    },
    webpack: {
      devtool: "inline-source-map"
    },
    preprocessors: {
      "plugins/**/*.test.js": ["webpack", "sourcemap", "babel"]
    },
    reporters: ["mocha"]
  });
};
