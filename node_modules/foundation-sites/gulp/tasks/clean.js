var gulp = require('gulp');
var rimraf = require('rimraf');

// Erases the dist folder
gulp.task('clean', function(done) {
  rimraf('_build', done);
});
