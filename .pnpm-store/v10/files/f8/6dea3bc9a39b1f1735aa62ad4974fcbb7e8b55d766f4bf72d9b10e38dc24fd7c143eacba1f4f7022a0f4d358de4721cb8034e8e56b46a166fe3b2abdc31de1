const generate = require('videojs-generate-karma-config');
const CI_TEST_TYPE = process.env.CI_TEST_TYPE || '';

module.exports = function(config) {

  // see https://github.com/videojs/videojs-generate-karma-config
  // for options
  const options = {
    coverage: CI_TEST_TYPE === 'coverage' ? true : false,
    preferHeadless: false,
    browsers(aboutToRun) {
      return aboutToRun.filter(function(launcherName) {
        return !(/^(Safari|Chromium)/).test(launcherName);
      });
    },
    files(defaults) {
      defaults.unshift('node_modules/es5-shim/es5-shim.js');
      defaults.unshift('node_modules/es6-shim/es6-shim.js');

      defaults.splice(
        defaults.indexOf('node_modules/video.js/dist/video.js'),
        1,
        'node_modules/video.js/dist/alt/video.core.js'
      );

      return defaults;
    },
    browserstackLaunchers(defaults) {
      delete defaults.bsSafariMojave;
      delete defaults.bsSafariElCapitan;

      // do not run on browserstack for coverage
      if (CI_TEST_TYPE === 'coverage') {
        defaults = {};
      }

      return defaults;
    },
    serverBrowsers() {
      return [];
    }
  };

  config = generate(config, options);

  // any other custom stuff not supported by options here!
};
