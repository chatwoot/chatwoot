const generate = require('videojs-generate-rollup-config');
const replace = require('@rollup/plugin-replace');
const dataFiles = require('rollup-plugin-data-files');

// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {
  input: 'src/index.js',
  externals(defaults) {
    defaults.module.push('@videojs/vhs-utils');

    return defaults;
  },
  primedPlugins(defaults) {
    // when using "require" rather than import
    // require cjs module
    defaults.replace = replace({
      // single quote replace
      "require('@videojs/vhs-utils/es": "require('@videojs/vhs-utils/cjs",
      // double quote replace
      'require("@videojs/vhs-utils/es': 'require("@videojs/vhs-utils/cjs'
    });

    defaults.dataFiles = dataFiles({
      expecteds: {include: 'test/fixtures/integration/*.js', transform: 'js', extensions: false},
      manifests: {include: 'test/fixtures/integration/*.m3u8', transform: 'string', extensions: false}
    });

    return defaults;
  },
  plugins(defaults) {
    defaults.module.unshift('replace');
    defaults.test.unshift('dataFiles');

    return defaults;
  }
};
const config = generate(options);

if (config.builds.test) {
  config.builds.test.output[0].format = 'umd';
}

// Add additonal builds/customization here!

// export the builds to rollup
export default Object.values(config.builds);
