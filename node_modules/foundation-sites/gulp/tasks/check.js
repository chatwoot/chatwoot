'use strict';

var gulp = require('gulp');
var checkDeps = require('gulp-check-deps');
var postcss = require('gulp-postcss');
var doiuse = require('doiuse');
var CONFIG = require('../config.js');

gulp.task('check', gulp.series('check:deps', 'check:browserSupport'));

// Check npm dependencies
gulp.task('check:deps', function() {
  return gulp.src('package.json').pipe(checkDeps());
});

// Check browser support
gulp.task('check:browserSupport', function() {
  return gulp.src(['_build/assets/css/foundation.css'])
    .pipe(postcss([doiuse({
      /* browsers: uses ".browserslistrc" */
      onFeatureUsage: function (usageInfo) {
        console.log(usageInfo.message)
      }
    })]))
});
