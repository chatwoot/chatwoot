const generate = require('videojs-generate-rollup-config');
const string = require('rollup-plugin-string').string;
const replace = require('@rollup/plugin-replace');

// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {
  input: 'src/index.js',
  plugins(defaults) {
    defaults.test.unshift('string');
    defaults.module.unshift('replace');

    return defaults;
  },
  primedPlugins(defaults) {
    defaults.string = string({include: ['test/manifests/*.mpd']});
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
  externals(defaults) {
    defaults.module.push('@videojs/vhs-utils');
    defaults.module.push('@xmldom/xmldom');
    defaults.module.push('atob');
    defaults.module.push('url-toolkit');
    return defaults;
  },
  globals(defaults) {
    defaults.browser['@xmldom/xmldom'] = 'window';
    defaults.browser.atob = 'window.atob';
    defaults.test['@xmldom/xmldom'] = 'window';
    defaults.test.atob = 'window.atob';
    defaults.test.jsdom = '{JSDOM: function() { return {window: window}; }}';
    return defaults;
  }
};
const config = generate(options);

if (config.builds.test) {
  config.builds.testNode = config.makeBuild('test', {
    input: 'test/**/*.test.js',
    output: [{
      name: `${config.settings.exportName}Tests`,
      file: 'test/dist/bundle-node.js',
      format: 'cjs'
    }]
  });

  config.builds.testNode.output[0].globals = {};
  config.builds.testNode.external = [].concat(config.settings.externals.module).concat([
    'jsdom',
    'qunit'
  ]);
}

// Add additonal builds/customization here!

// export the builds to rollup
export default Object.values(config.builds);
