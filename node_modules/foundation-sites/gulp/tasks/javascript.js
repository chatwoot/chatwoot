var gulp = require('gulp');
var concat = require('gulp-concat');
var webpackStream = require('webpack-stream');
var webpack = require('webpack');
var named = require('vinyl-named');
var sourcemaps = require('gulp-sourcemaps');

var utils = require('../utils.js');
var CONFIG = require('../config.js');

// ----- WEBPACK CONFIGURATION -----
//
// The following sets up all imports from within Foundation as externals, for the purpose
// of replicating the "drop in dist file" approach of prior versions.
// THIS IS NOT RECOMMENDED FOR MOST USERS. Chances are you either want everything
// (just throw in foundation.js or foundation.min.js) or you should be using a build
// system.

//
// Generate the webpack "Externals" configuration for UMD modules.
// This tells webpack that the modules imported with the listed paths should not
// be included in the build but will be provided later from an external source.
//
// `umdExternals` is used to generate the webpack "externals" configuration:
// an object indicating to different module tools under which name our modules
// are declared. "root" is the global variable name to use in module-less
// environments (or in the namespace if given).
//
// See https://webpack.js.org/configuration/externals/#externals
//
var webpackExternalPlugins = Object.assign(
  // | Module import path             | External source names and paths
  utils.umdExternals({
    'jquery': { root: 'jQuery' },
  }),
  utils.umdExternals({
    './foundation.core':              { root: 'foundation.core', default: './foundation.core' },
    './foundation.core.utils':        { root: 'foundation.core', default: './foundation.core' },
    './foundation.core.plugin':       { root: 'foundation.core', default: './foundation.core' },
    './foundation.util.imageLoader':  { root: 'foundation.util.imageLoader' },
    './foundation.util.keyboard':     { root: 'foundation.util.keyboard' },
    './foundation.util.mediaQuery':   { root: 'foundation.util.mediaQuery' },
    './foundation.util.motion':       { root: 'foundation.util.motion' },
    './foundation.util.nest':         { root: 'foundation.util.nest' },
    './foundation.util.timer':        { root: 'foundation.util.timer' },
    './foundation.util.touch':        { root: 'foundation.util.touch' },
    './foundation.util.box':          { root: 'foundation.util.box' },
    './foundation.dropdownMenu':      { root: 'foundation.dropdownMenu' },
    './foundation.drilldown':         { root: 'foundation.drilldown' },
    './foundation.accordionMenu':     { root: 'foundation.accordionMenu' },
    './foundation.accordion':         { root: 'foundation.accordion' },
    './foundation.tabs':              { root: 'foundation.tabs' },
    './foundation.smoothScroll':      { root: 'foundation.smoothScroll' },
  }, {
    // Search for the module in this global variable in module-less environments.
    namespace: CONFIG.JS_BUNDLE_NAMESPACE
  })
);

// The webpack "output" configuration for UMD modules.
// Makes the modules being exported as UMD modules. In module-less environments,
// modules will be stored in the global variable defined by JS_BUNDLE_NAMESPACE.
var webpackOutputAsExternal = {
  library: [CONFIG.JS_BUNDLE_NAMESPACE, '[name]'],
  libraryTarget: 'umd',
};

var webpackConfig = {
  mode: 'development',
  externals: utils.umdExternals({
    // Use the global jQuery object "jQuery" in module-less environments.
    'jquery': { root: 'jQuery' },
  }),
  module: {
    rules: [
      {
        test: /.js$/,
        use: [
          {
            loader: 'babel-loader'
          }
        ]
      }
    ]
  },
  output: {
    libraryTarget: 'umd',
  },
  // https://github.com/shama/webpack-stream#source-maps
  devtool: 'source-map',
  stats: {
    chunks: false,
    entrypoints: false,
  }
}

// ----- TASKS -----
//

// Compiles JavaScript into a single file
gulp.task('javascript', gulp.series('javascript:foundation', 'javascript:deps', 'javascript:docs'));

// Core has to be dealt with slightly differently due to bootstrapping externals
// and the dependency on foundation.core.utils
//
gulp.task('javascript:plugin-core', function() {
  return gulp.src('js/entries/plugins/foundation.core.js')
    .pipe(named())
    .pipe(sourcemaps.init())
    .pipe(webpackStream(Object.assign({}, webpackConfig, {
        output: webpackOutputAsExternal,
      }), webpack))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('_build/assets/js/plugins'));
});
gulp.task('javascript:plugins', gulp.series('javascript:plugin-core', function () {
  return gulp.src(['js/entries/plugins/*.js', '!js/entries/plugins/foundation.core.js'])
    .pipe(named())
    .pipe(sourcemaps.init())
    .pipe(webpackStream(Object.assign({}, webpackConfig, {
        externals: webpackExternalPlugins,
        output: webpackOutputAsExternal,
      }), webpack))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('_build/assets/js/plugins'));
}));

gulp.task('javascript:foundation', gulp.series('javascript:plugins', function() {
  return gulp.src('js/entries/foundation.js')
    .pipe(named())
    .pipe(sourcemaps.init())
    .pipe(webpackStream(webpackConfig, webpack))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('_build/assets/js'));
}));

gulp.task('javascript:deps', function() {
  return gulp.src(CONFIG.JS_DEPS)
    .pipe(concat('vendor.js'))
    .pipe(gulp.dest('_build/assets/js'));
});

gulp.task('javascript:docs', function() {
  return gulp.src(CONFIG.JS_DOCS)
    .pipe(concat('docs.js'))
    .pipe(gulp.dest('_build/assets/js'));
});
