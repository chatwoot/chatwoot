const generate = require('videojs-generate-rollup-config');
const replace = require('@rollup/plugin-replace');

// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {
  input: 'src/index.js',
  externals(defaults) {
    defaults.module.push('pkcs7');
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

    return defaults;
  },
  plugins(defaults) {
    defaults.module.unshift('replace');

    return defaults;
  }
};
const config = generate(options);

// Add additonal builds/customization here!

// export the builds to rollup
export default Object.values(config.builds);
