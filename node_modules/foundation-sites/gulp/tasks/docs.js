var cacheBust = require('gulp-cache-bust');
var foundationDocs = require('foundation-docs');
var gulp = require('gulp');
var newer = require('gulp-newer');
var panini = require('panini');
var supercollider = require('supercollider');

var PANINI_CONFIG = {
  root: 'docs/pages/',
  layouts: 'docs/layout/',
  partials: ['docs/partials/', 'node_modules/foundation-docs/templates/partials/'],
  helpers: foundationDocs.handlebarsHelpers,
}

var SEARCH_SORT_ORDER = ['page', 'component', 'sass variable', 'sass mixin', 'sass function', 'js class', 'js function', 'js plugin option', 'js event'];

var SEARCH_PAGE_TYPES = {
  'library': function(item) {
    return !!(item.library);
  }
}

supercollider
  .config({
    template: foundationDocs.componentTemplate,
    marked: foundationDocs.marked,
    handlebars: foundationDocs.handlebars,
    keepFm: true,
    quiet: false,
    pageRoot: 'docs/pages',
    data: {
      repoName: 'foundation-sites',
      editBranch: 'develop'
    }
  })
  .searchConfig({
    extra: 'docs/search.yml',
    sort: SEARCH_SORT_ORDER,
    pageTypes: SEARCH_PAGE_TYPES
  })
  .adapter('sass')
  .adapter('js');

// Build the search entries
gulp.task('docs:search', function (done) {
  supercollider.buildSearch('_build/data/search.json', done);
});

// Assembles the modified layout, pages, and partials in the docs folder
gulp.task('docs:pages', function() {
  return gulp.src('docs/pages/**/*')
    .pipe(newer({
      dest: '_build',
      ext: '.html'
    }))
    .pipe(supercollider.init())
    .pipe(panini(PANINI_CONFIG))
    .pipe(cacheBust({
      basePath: '_build/'
    }))
    .pipe(gulp.dest('_build'));
});

// Assembles layout, pages, and partials in the docs folder, even if not modified
gulp.task('docs:pages:all', function() {
  panini.refresh();

  return gulp.src('docs/pages/**/*')
    .pipe(supercollider.init())
    .pipe(panini(PANINI_CONFIG))
    .pipe(cacheBust({
      basePath: '_build/'
    }))
    .pipe(gulp.dest('_build'));
});

gulp.task('docs:debug', gulp.series('docs:all', function(done) {
  var output = JSON.stringify(supercollider.tree, null, '  ');
  require('fs').writeFile('./_debug.json', output, done);
}));

gulp.task('docs', gulp.series('docs:pages', 'docs:search'));
gulp.task('docs:all', gulp.series('docs:pages:all', 'docs:search'));
