'use strict';

var fs = require('fs');
var gulp = require('gulp');
var Parker = require('parker/lib/Parker');
var prettyJSON = require('prettyjson');
var sass = require('gulp-sass');
var plumber = require('gulp-plumber');
var sourcemaps = require('gulp-sourcemaps');
var sassLint = require('gulp-sass-lint');
var postcss = require('gulp-postcss');
var autoprefixer = require('autoprefixer');

var CONFIG = require('../config.js');

// Compiles Sass files into CSS
gulp.task('sass', gulp.series('sass:foundation', 'sass:docs'));

// Prepare dependencies
gulp.task('sass:deps', function() {
  return gulp.src(CONFIG.SASS_DEPS_FILES)
    .pipe(gulp.dest('_vendor'));
});

// Compiles Foundation Sass
gulp.task('sass:foundation', gulp.series('sass:deps', function() {
  return gulp.src(['assets/*'])
    .pipe(sourcemaps.init())
    .pipe(plumber())
    .pipe(sass().on('error', sass.logError))
    .pipe(postcss([autoprefixer()])) // uses ".browserslistrc"
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('_build/assets/css'));
}));

// Compiles docs Sass (includes Foundation code also)
gulp.task('sass:docs', gulp.series('sass:deps', function() {
  return gulp.src('docs/assets/scss/docs.scss')
    .pipe(sourcemaps.init())
    .pipe(sass({
      includePaths: CONFIG.SASS_DOC_PATHS
    }).on('error', sass.logError))
    .pipe(postcss([autoprefixer()])) // uses ".browserslistrc"
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('_build/assets/css'));
}));

// Audits CSS filesize, selector count, specificity, etc.
gulp.task('sass:audit', gulp.series('sass:foundation', function(done) {
  fs.readFile('./_build/assets/css/foundation.css', function(err, data) {
    var parker = new Parker(require('parker/metrics/All'));
    var results = parker.run(data.toString());
    console.log(prettyJSON.render(results));
    done();
  });
}));
