const createTestData = require('./create-test-data.js');
const generate = require('videojs-generate-rollup-config');
// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {
  input: 'src/index.js',
  exportName: 'vhsUtils',
  distName: 'vhs-utils',
  primedPlugins(defaults) {
    return Object.assign(defaults, {
      createTestData: createTestData()
    });
  },
  plugins(defaults) {
    defaults.test.splice(0, 0, 'createTestData');
    return defaults;
  }
};
const config = generate(options);

if (config.builds.module) {
  delete config.builds.module;
}

// Add additonal builds/customization here!

// export the builds to rollup
export default Object.values(config.builds);
