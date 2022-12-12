'use strict';
var _ = require('lodash');
var fs = require('fs');
var Q = require('q');
var gulp = require('gulp');
var autoprefixer = require('gulp-autoprefixer');
var sass = require('gulp-sass');
var del = require('del');

var htmlDir = './examples',
    cssDir = './css',
    scssDir = './scss',
    htmlTmpl = '<!DOCTYPE html>\n\
<html>\n\
<head>\n\
  <title><%= title %></title>\n\
  <style type="text/css">\n\
    <%= css %>\n\
  </style>\n\
</head>\n\
<body>\n\
 <%= bodyContent %>\n\
</body>\n\
</html>';

var getHtmlUsageExample = function(cssContent) {
  var match = cssContent.match(/Usage:([\s\S]+\*[.\s\S]+\>)/);
  return match && match.length > 1 ? match[1].replace(/ \*/g, '') : '';
};

gulp.task('clean-styles', function(cb) {
  del([cssDir], cb);
});


gulp.task('styles', ['clean-styles'], function() {
  return gulp.src(scssDir + '/**/*.scss')
             .pipe(sass({errLogToConsole: true}))
             .pipe(autoprefixer('last 2 versions', {map: false}))
             .pipe(gulp.dest(cssDir));
});


gulp.task('clean-html', function(cb) {
  del([htmlDir], cb);
});


// Generates HTML files from the usage examples found in the CSS files
gulp.task('html', ['styles', 'clean-html'], function() {
  var spinnersDir = cssDir + '/spinners/';
  var allDeferred = Q.defer();

  fs.mkdirSync(htmlDir);

  fs.readdir(spinnersDir, function(err, filenames) {
    var promises = filenames.map(function(filename) {
      if (filename.indexOf('.css') === -1) { return; }
      var deferred = Q.defer();
      var title = filename.replace('.css', '').replace(/-/g, ' ');
      var cssFilepath = spinnersDir + filename;
      var htmlFilename = filename.replace('.css', '.html');

      var readCssFile = function(err, cssContent) {
        if (err) { console.log(err); deferred.reject(err); }
        var bodyContent = getHtmlUsageExample(cssContent);
        var html = _.template(htmlTmpl)({
          css: cssContent,
          title: title,
          bodyContent: bodyContent
        });
        fs.writeFile(htmlDir + '/' + htmlFilename, html, function(err, data) {
          if (err) { console.log(err); deferred.reject(err); }
          deferred.resolve();
        });
      };

      fs.readFile(cssFilepath, {encoding: 'utf8'}, readCssFile);
      return deferred.promise;
    });
    Q.all(promises).then(allDeferred.resolve);

  });

  return allDeferred;
});


gulp.task('build', ['html', 'styles']);


gulp.task('default', ['build']);


gulp.task('watch', ['build'], function() {
  gulp.watch(scssDir + '/**/*.scss', ['build']);
});
