const generate = require('videojs-generate-rollup-config');

// see https://github.com/videojs/videojs-generate-rollup-config
// for options
const options = {input: 'src/pkcs7.js'};
const config = generate(options);

// Add additonal builds/customization here!

config.builds = Object.assign(config.builds, {
  pad: config.makeBuild('browser', {
    input: 'src/pad.js',
    output: [{
      name: 'pkcs7.pad',
      file: 'dist/pkcs7.pad.js',
      format: 'umd'
    }, {
      name: 'pkcs7.pad',
      file: 'dist/pkcs7.pad.min.js',
      format: 'umd'
    }]
  }),
  unpad: config.makeBuild('browser', {
    input: 'src/unpad.js',
    output: [{
      name: 'pkcs7.unpad',
      file: 'dist/pkcs7.unpad.js',
      format: 'umd'
    }, {
      name: 'pkcs7.unpad',
      file: 'dist/pkcs7.unpad.min.js',
      format: 'umd'
    }]
  })
});

// export the builds to rollup
export default Object.values(config.builds);
