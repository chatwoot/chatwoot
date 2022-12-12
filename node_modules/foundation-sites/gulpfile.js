var gulp = require('gulp');
var browser = require('browser-sync');
var requireDir = require('require-dir');
var forwardReference = require('undertaker-forward-reference');
var port = process.env.SERVER_PORT || 3000;

// Make Gulp accepting reference to tasks that are not declared yet, like in v3.
gulp.registry(forwardReference());

requireDir('./gulp/tasks');

function browserReloadSync(done) {
  browser.reload();
  done();
}

// Builds the documentation and framework files
gulp.task('build', gulp.series('clean', 'copy', 'sass', 'javascript', 'lint:graceful', 'docs:all'));

// Starts a BrowerSync instance
gulp.task('serve', gulp.series('build', function(done){
  browser.init({server: './_build', port: port});
  done();
}));

// Watch files for changes
gulp.task('watch', function() {
  gulp.watch('docs/**/*', gulp.series('docs', browserReloadSync));
  gulp.watch(['docs/layout/*.html', 'docs/partials/*{html,hbs}', 'docs/assets/partials/*{html,hbs}', 'node_modules/foundation-docs/templates/*{html,hbs}'], gulp.series('docs:all', browserReloadSync));
  gulp.watch('scss/**/*', gulp.series('sass', browserReloadSync));
  gulp.watch(['docs/assets/scss/**/*', 'node_modules/foundation-docs/scss/**/*'], gulp.series('sass:docs', browserReloadSync));
  gulp.watch('js/**/*', gulp.series('javascript:foundation', browserReloadSync));
  gulp.watch(['docs/assets/js/**/*', 'node_modules/foundation-docs/js/**/*'], gulp.series('javascript:docs', browserReloadSync));
});

// Runs all of the above tasks and then waits for files to change
gulp.task('default', gulp.series('serve', 'watch'));
