var $      = require('gulp-load-plugins')();
var argv   = require('yargs').argv;
var gulp   = require('gulp');
var rimraf = require('rimraf');
var panini = require('panini');
var sequence = require('run-sequence');

// Check for --production flag
var isProduction = !!(argv.production);

// File paths to various assets are defined here.
var paths = {
  assets: [
    'src/assets/**/*',
    '!src/assets/{!img,js,scss}/**/*'
  ],
  downloads: [
    'src/downloads/**/*.*'
  ],
  sass: [
    'node_modules/foundation-sites/scss'
  ],
  javascript: [
    'node_modules/jquery/dist/jquery.js',
    'node_modules/foundation-sites/dist/foundation.js',
    'node_modules/what-input/what-input.js',
    'src/assets/js/**/*.js',
    'node_modules/lodash/lodash.js',
    'src/assets/js/app.js'
  ]
};

// Delete the "dist" folder
// This happens every time a build starts
gulp.task('clean', function(done) {
  rimraf('./dist', done);
});

// Copy files out of the assets folder
// This task skips over the "img", "js", and "scss" folders, which are parsed separately
gulp.task('copy', function(done) {
  gulp.src(paths.assets)
    .pipe(gulp.dest('./dist/assets'));
});
gulp.task('downloads', function(done){
  gulp.src('src/downloads/**/*.*')
      .pipe(gulp.dest('./dist/downloads'));
      done();
});

// Copy page templates into finished HTML files
gulp.task('pages', function() {
  gulp.src('./src/pages/**/*.html')
    .pipe(panini({
      root: './src/pages/',
      layouts: './src/layouts/',
      partials: './src/partials/',
      data: './src/data/'
    }))
    .pipe($.cacheBust({ type: 'MD5' }))
    .pipe(gulp.dest('./dist'));
});

gulp.task('pages:reset', function() {
  panini.refresh();
  gulp.run('pages');
});

// Compile Sass into CSS
// In production, the CSS is compressed
gulp.task('sass', function() {
  var uncss = $.if(isProduction, $.uncss({
    html: ['src/**/*.html'],
    ignore: [
      new RegExp('^meta\..*'),
      new RegExp('^\.is-.*')
    ]
  }));

  return gulp.src('./src/assets/scss/app.scss')
    .pipe($.sass({
      includePaths: paths.sass,
      outputStyle: isProduction ? 'compressed' : 'nested'
    })
      .on('error', $.sass.logError))
    .pipe($.autoprefixer()) // uses ".browserslistrc"
    // .pipe(uncss)
    .pipe(gulp.dest('./dist/assets/css'));
});

// Combine JavaScript into one file
// In production, the file is minified
gulp.task('javascript', function() {
  var uglify = $.if(isProduction, $.uglify({
      mangle: false
    })
    .on('error', function (e) {
      console.log(e);
    }));

  return gulp.src(paths.javascript)
    .pipe($.concat('app.js'))
    .pipe(uglify)
    .pipe(gulp.dest('./dist/assets/js'));
});

// Compiles HTML templates into JST
gulp.task('jst', function() {
  gulp.src('src/templates/*.html')
    .pipe($.jstConcat('templates.js', {
      renameKeys: ['^.*marketing/(src.*.html)$', '$1']
    }))
    .pipe(gulp.dest('dist/assets/js'));
});

// Copy images to the "dist" folder
// In production, the images are compressed
gulp.task('images', function() {
  var imagemin = $.if(isProduction, $.imagemin({
    progressive: true
  }));

  return gulp.src('./src/assets/img/**/*')
    // .pipe(imagemin)
    .pipe(gulp.dest('./dist/assets/img'));
});

// Deploy to the live server
gulp.task('deploy', ['build'], function() {
  return gulp.src('./dist/**')
    .pipe($.prompt.confirm('Make sure everything looks right before you deploy.'))
    .pipe($.rsync({
      root: './dist',
      hostname: 'deployer@72.32.134.77',
      destination: '/home/deployer/sites/foundation-sites-6-marketing'
    }));
});

// Build the "dist" folder by running all of the above tasks
gulp.task('build', function(done) {
  sequence('clean', ['pages', 'sass', 'javascript', 'images', 'jst', 'downloads'], done);
});

// Start a server with LiveReload to preview the site in
gulp.task('server', ['build'], function() {
  return gulp.src('./dist')
    .pipe($.webserver({
      host: 'localhost',
      port: 8000,
      livereload: true,
      open: true
    }));
});

// Build the site, run the server, and watch for file changes
gulp.task('default', ['build', 'server'], function() {
  gulp.watch(paths.assets, ['copy']);
  gulp.watch(['./src/pages/**/*.html'], ['pages']);
  gulp.watch(['./src/{layouts,partials}/**/*.html'], ['pages:reset']);
  gulp.watch(['./src/assets/scss/**/*.scss'], ['sass']);
  gulp.watch(['./src/assets/js/**/*.js'], ['javascript']);
  gulp.watch(['node_modules/foundation-sites/dist/foundation.js'], ['javascript']);
  gulp.watch(['./src/assets/img/**/*'], ['images']);
  gulp.watch(['./src/templates/**/*'], ['jst']);
});
