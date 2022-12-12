var fs = require('fs');
var path = require('path');
var mkdirp = require('mkdirp');
var uglify = require('uglify-js');
var rollup = require('rollup');
var replace = require('rollup-plugin-replace');

Promise
  .all([
    generateCommonModule(),
    generateBundledDev(),
    generateBundledProd(),
  ]);

function generateCommonModule() {
  return rollup
    .rollup({
      entry: 'index.js',
      external: [ 'vue' ],
    })
    .then(function(bundle) {
      return bundle.generate({
        format: 'cjs',
      }).code;
    })
    .then(function(code) {
      write('dist/vue-clickaway.common.js', code);
    });
}

function generateBundledDev() {
  return rollup
    .rollup({
      entry: 'index.js',
      external: [ 'vue' ],
      plugins: [
        replace({
          'process.env.NODE_ENV': '\'development\'',
        }),
      ],
    })
    .then(function(bundle) {
      return bundle.generate({
        format: 'iife',
        moduleName: 'VueClickaway',
        globals: { vue: 'Vue' },
      }).code;
    })
    .then(function(code) {
      write('dist/vue-clickaway.js', code);
    });
}

function generateBundledProd() {
  return rollup
    .rollup({
      entry: 'index.js',
      external: [ 'vue' ],
      plugins: [
        replace({
          'process.env.NODE_ENV': '\'production\'',
        }),
      ],
    })
    .then(function(bundle) {
      return bundle.generate({
        format: 'iife',
        moduleName: 'VueClickaway',
        globals: { vue: 'Vue' },
      }).code;
    })
    .then(function(code) {
      return uglify.minify(code, {
        fromString: true,
      }).code;
    })
    .then(function(code) {
      return write('dist/vue-clickaway.min.js', code);
    }); 
}

function write(dest, code) {
  return new Promise(function(resolve, reject) {
    mkdirp(path.dirname(dest), function(err) {
      if (err) return reject(err);
      fs.writeFile(dest, code, function(err) {
        if (err) return reject(err);
        resolve();
      });
    });
  });
}
