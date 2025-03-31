const generate = require('videojs-generate-rollup-config');
const worker = require('rollup-plugin-worker-factory');
const {terser} = require('rollup-plugin-terser');
const createTestData = require('./create-test-data.js');
const replace = require('@rollup/plugin-replace');
const strip = require('@rollup/plugin-strip');

const CI_TEST_TYPE = process.env.CI_TEST_TYPE || '';

let syncWorker;
// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {
  input: 'src/videojs-http-streaming.js',
  distName: 'videojs-http-streaming',
  excludeCoverage(defaults) {
    defaults.push(/^rollup-plugin-worker-factory/);
    defaults.push(/^create-test-data!/);

    return defaults;
  },
  globals(defaults) {
    defaults.browser['@xmldom/xmldom'] = 'window';
    defaults.test['@xmldom/xmldom'] = 'window';
    return defaults;
  },
  externals(defaults) {
    return Object.assign(defaults, {
      module: defaults.module.concat([
        'aes-decrypter',
        'm3u8-parser',
        'mpd-parser',
        'mux.js',
        '@videojs/vhs-utils'
      ])
    });
  },
  plugins(defaults) {
    // add worker and createTestData to the front of plugin lists
    defaults.module.unshift('worker');
    defaults.browser.unshift('worker');
    // change this to `syncWorker` for syncronous web worker
    // during unit tests
    if (CI_TEST_TYPE === 'coverage') {
      defaults.test.unshift('syncWorker');
    } else {
      defaults.test.unshift('worker');
    }
    defaults.test.unshift('createTestData');

    if (CI_TEST_TYPE === 'playback-min') {
      defaults.test.push('uglify');
    }

    // istanbul is only in the list for regular builds and not watch
    if (CI_TEST_TYPE !== 'coverage' && defaults.test.indexOf('istanbul') !== -1) {
      defaults.test.splice(defaults.test.indexOf('istanbul'), 1);
    }
    defaults.module.unshift('replace');

    defaults.module.unshift('strip');
    defaults.browser.unshift('strip');

    return defaults;
  },
  primedPlugins(defaults) {
    defaults = Object.assign(defaults, {
      replace: replace({
        // single quote replace
        "require('@videojs/vhs-utils/es": "require('@videojs/vhs-utils/cjs",
        // double quote replace
        'require("@videojs/vhs-utils/es': 'require("@videojs/vhs-utils/cjs'
      }),
      uglify: terser({
        output: {comments: 'some'},
        compress: {passes: 2}
      }),
      strip: strip({
        functions: ['TEST_ONLY_*'],
        debugger: false,
        sourceMap: false
      }),
      createTestData: createTestData()
    });

    defaults.worker = worker({type: 'browser', plugins: [
      defaults.resolve,
      defaults.json,
      defaults.commonjs,
      defaults.babel
    ]});

    defaults.syncWorker = syncWorker = worker({type: 'mock', plugins: [
      defaults.resolve,
      defaults.json,
      defaults.commonjs,
      defaults.babel
    ]});

    return defaults;
  },
  babel(defaults) {
    const presetEnvSettings = defaults.presets[0][1];

    presetEnvSettings.exclude = presetEnvSettings.exclude || [];
    presetEnvSettings.exclude.push('@babel/plugin-transform-typeof-symbol');

    return defaults;
  }
};

if (CI_TEST_TYPE === 'playback' || CI_TEST_TYPE === 'playback-min') {
  options.testInput = 'test/playback.test.js';
} else if (CI_TEST_TYPE === 'unit' || CI_TEST_TYPE === 'coverage') {
  options.testInput = {include: ['test/**/*.test.js'], exclude: ['test/playback.test.js']};
}

const config = generate(options);

if (config.builds.browser) {
  config.builds.syncWorkers = config.makeBuild('browser', {
    output: {
      name: 'httpStreaming',
      format: 'umd',
      file: 'dist/videojs-http-streaming-sync-workers.js'
    }
  });

  config.builds.syncWorkers.plugins[0] = syncWorker;
}

// Add additonal builds/customization here!

// export the builds to rollup
export default Object.values(config.builds);
