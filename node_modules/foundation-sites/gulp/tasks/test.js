var gulp = require('gulp');
var browser = require('browser-sync');
var concat = require('gulp-concat');
var babel = require('gulp-babel');
var onBabelError = require('./babel-error.js');
var rimraf = require('rimraf').sync;

var CONFIG = require('../config.js');

// Runs unit tests
gulp.task('test', gulp.series('sass:foundation', 'test:transpile-js', gulp.parallel('watch', 'test:watch')));

gulp.task('test:watch', function () {
  browser.init({
    server: {
      baseDir: 'test/visual',
      directory: true,
      routes: {
        "/assets": "_build/assets",
        "/motion-ui": "node_modules/motion-ui"
      }
    }
  });
  gulp.watch(['test/visual/**/*'], gulp.series('test:reload'));
});

gulp.task('test:reload', function(done) {
  browser.reload();
  done();
});

gulp.task('test:transpile-js', gulp.series('javascript:foundation', 'javascript:deps', function () {
  rimraf('test/javascript/js-tests.js');

  return gulp.src(CONFIG.TEST_JS_FILES)
    .pipe(babel()
      .on('error', onBabelError))
    .pipe(concat('js-tests.js'))
    .pipe(gulp.dest('test/javascript'))
}));
