var gulp = require('gulp');
var sassLint = require('gulp-sass-lint');
var eslint = require('gulp-eslint');
var CONFIG = require('../config.js');

// Lints Sass and JavaScript files for formatting issues
gulp.task('lint', gulp.series('lint:sass', 'lint:javascript'));

// Lints Sass and Javascript without throwing error
gulp.task('lint:graceful', gulp.series('lint:graceful:sass', 'lint:graceful:javascript'));

function lintSass() {
  return gulp.src(CONFIG.SASS_LINT_FILES)
    .pipe(sassLint({
      config: './.sass-lint.yml'
    }))
    .pipe(sassLint.format());
}

function lintJavascript() {
  return gulp.src(CONFIG.JS_FILES)
    .pipe(eslint({
      useEslintrc: true,
      configFile: '.eslintrc'
    }))
    .pipe(eslint.format());
}

gulp.task('lint:sass', function () {
  return lintSass()
    .pipe(sassLint.failOnError());
});
gulp.task('lint:javascript', function () {
  return lintJavascript()
  .pipe(eslint.failAfterError());
});

gulp.task('lint:graceful:sass', lintSass);
gulp.task('lint:graceful:javascript', lintJavascript);
