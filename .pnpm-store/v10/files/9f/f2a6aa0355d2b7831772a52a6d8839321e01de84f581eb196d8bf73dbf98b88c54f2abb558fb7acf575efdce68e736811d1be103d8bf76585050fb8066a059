const baseConfig = require("./karma.conf.js");

const customLaunchers = {
  sl_chrome_latest: {
    base: "SauceLabs",
    browserName: "chrome",
    platform: "linux",
    version: "latest"
  },
  sl_chrome_latest_1: {
    base: "SauceLabs",
    browserName: "chrome",
    platform: "linux",
    version: "latest"
  },
  sl_firefox_latest: {
    base: "SauceLabs",
    browserName: "firefox",
    platform: "linux",
    version: "latest"
  },
  sl_firefox_latest_1: {
    base: "SauceLabs",
    browserName: "firefox",
    platform: "linux",
    version: "latest-1"
  },
  sl_safari_9: {
    base: "SauceLabs",
    browserName: "safari",
    version: "9.0"
  },
  sl_edge_latest: {
    base: "SauceLabs",
    browserName: "microsoftedge"
  }
};

module.exports = function(config) {
  baseConfig(config);

  if (!process.env.SAUCE_USERNAME || !process.env.SAUCE_ACCESS_KEY) {
    throw new Error(
      "SAUCE_USERNAME and SAUCE_ACCESS_KEY environment variables are required but are missing"
    );
  }

  config.set({
    browserDisconnectTolerance: 1,

    singleRun: true,

    reporters: ["dots", "saucelabs"],

    browsers: Object.keys(customLaunchers),

    customLaunchers,

    sauceLabs: {
      testName: require("./package.json").name
    },

    coverageReporter: {
      reporters: [{ type: "lcov" }]
    }
  });
};
