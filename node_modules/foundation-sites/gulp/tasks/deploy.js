var gulp = require('gulp');
var filter = require('gulp-filter');
var cleancss = require('gulp-clean-css');
var rename = require('gulp-rename');
var uglify = require('gulp-uglify');
var confirm = require('gulp-prompt').confirm;
var rsync = require('gulp-rsync');
var replace = require('gulp-replace');
var octophant = require('octophant');
var inquirer = require('inquirer');
var exec = require('child_process').execSync;
var plumber = require('gulp-plumber');
var sourcemaps = require('gulp-sourcemaps');
var rollup = require('rollup');

var ROLLUP_CONFIG = require('../../rollup.config.js');
var CONFIG = require('../config.js');
var CURRENT_VERSION = require('../../package.json').version;
var NEXT_VERSION;

gulp.task('deploy', gulp.series('deploy:prompt', 'deploy:version', 'deploy:dist', 'deploy:plugins', 'deploy:settings', 'deploy:commit', 'deploy:templates'));

gulp.task('deploy:prep', gulp.series('deploy:prompt', 'deploy:version', 'deploy:dist', 'deploy:plugins', 'deploy:settings'));
gulp.task('deploy:dist', gulp.series('sass:foundation', 'javascript:foundation', 'deploy:dist:files', 'deploy:dist:bundles'));
gulp.task('deploy:plugins', gulp.series('deploy:plugins:sources', 'deploy:plugins:sourcemaps'));

gulp.task('deploy:prompt', function(cb) {
  inquirer.prompt([{
    type: 'input',
    name: 'version',
    message: 'What version are we moving to? (Current version is ' + CURRENT_VERSION + ')'
  }])
  .then(function(res) {
    NEXT_VERSION = res.version;
    cb();
  });
});

// Bumps the version number in any file that has one
gulp.task('deploy:version', function() {
  return gulp.src(CONFIG.VERSIONED_FILES, { base: process.cwd() })
  .pipe(replace(CURRENT_VERSION, NEXT_VERSION))
  .pipe(gulp.dest('.'));
});

// Generates compiled CSS and JS files and sourcemaps and puts them in the dist/ folder
gulp.task('deploy:dist:files', function() {
  var cssFilter = filter(['**/*.css'], { restore: true });
  var jsFilter  = filter(['**/*.js'], { restore: true });
  var cssSourcemapFilter = filter(['**/*.css.map'], { restore: true });
  var jsSourcemapFilter = filter(['**/*.js.map'], { restore: true });
  var tsFilter  = filter(['**/*.ts'], { restore: true });

  return gulp.src(CONFIG.DIST_FILES)
    .pipe(plumber())

    // --- Source maps ---
    // * Copy sourcemaps to the dist folder
    // This is done first to avoid collision with minified-sourcemaps.
    .pipe(cssSourcemapFilter)
      .pipe(gulp.dest('./dist/css'))
      .pipe(cssSourcemapFilter.restore)
    .pipe(jsSourcemapFilter)
      .pipe(gulp.dest('./dist/js'))
      .pipe(jsSourcemapFilter.restore)

    // --- Source files ---
    // * Copy source files to dist folder
    // * Create minified files
    // * Create minified-sourcemaps based on standard sourcemaps.
    //   Sourcemaps are initialized before the ".min" renaming to be able retrieve
    //   original sourcemaps from source names.
    .pipe(cssFilter)
      .pipe(gulp.dest('./dist/css'))
      .pipe(sourcemaps.init({ loadMaps: true }))
      .pipe(rename({ suffix: '.min' }))
      .pipe(cleancss({ compatibility: 'ie9' }))
      .pipe(sourcemaps.write('.'))
      .pipe(gulp.dest('./dist/css'))
      .pipe(cssFilter.restore)

    .pipe(jsFilter)
      .pipe(gulp.dest('./dist/js'))
      .pipe(sourcemaps.init({ loadMaps: true }))
      .pipe(rename({ suffix: '.min' }))
      .pipe(uglify())
      .pipe(sourcemaps.write('.'))
      .pipe(gulp.dest('./dist/js'))
      .pipe(jsFilter.restore)

    // --- TypeScript files ---
    // * Copy typescript files to the dist folder
    .pipe(tsFilter)
      .pipe(gulp.dest('./dist/js'))
      .pipe(tsFilter.restore);
});

//
// Generates JS bundles and puts them in the dist/ folder.
//
// In addition to the UMD bundle coming from the build task, the following
// formats are generated: CJS, ESM, ES6.
// See "rollup.config.js" for more information.
//
gulp.task('deploy:dist:bundles', gulp.series(
  // Create a subtask for each Rollup config
  ...ROLLUP_CONFIG.map((config) => function () {

    // Run rollup with the Rollup config
    return rollup.rollup(config)
      .then(bundle => bundle.write(config.output));
  })
));

// Copies standalone JavaScript plugins to dist/ folder
gulp.task('deploy:plugins:sources', function () {
  return gulp.src('_build/assets/js/plugins/*.js')
    .pipe(gulp.dest('dist/js/plugins'))
    .pipe(sourcemaps.init({ loadMaps: true }))
    .pipe(rename({ suffix: '.min' }))
    .pipe(uglify())
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('dist/js/plugins'));
});

// Copies standalone JavaScript plugins sourcemaps to dist/ folder
gulp.task('deploy:plugins:sourcemaps', function () {
  return gulp.src('_build/assets/js/plugins/*.js.map')
    .pipe(gulp.dest('dist/js/plugins'));
});

// Generates a settings file
gulp.task('deploy:settings', function(done) {
  var options = {
    title: 'Foundation for Sites Settings',
    output: './scss/settings/_settings.scss',
    groups: {
      'grid': 'The Grid',
      'off-canvas': 'Off-canvas',
      'typography-base': 'Base Typography'
    },
    sort: [
      'global',
      'breakpoints',
      'grid',
      'typography-base',
      'typography-helpers'
    ],
    imports: ['util/util'],
    _foundationShim: true
  }

  octophant('./scss', options, done);
});

// Writes a commit with the changes to the version numbers
gulp.task('deploy:commit', function() {
  exec('git commit -am "Bump to version "' + NEXT_VERSION);
  exec('git tag v' + NEXT_VERSION);
  exec('git push origin develop --follow-tags');
});

// Uploads the documentation to the live server
gulp.task('deploy:docs', gulp.series('build', function() {
  return gulp.src('./_build/**')
    .pipe(confirm('Make sure everything looks right before you deploy.'))
    .pipe(rsync({
      root: './_build',
      hostname: 'deployer@72.32.134.77',
      destination: '/home/deployer/sites/foundation-sites-6-docs'
    }));
}));

// Uploads the documentation to the live server in beta env
gulp.task('deploy:beta', gulp.series('build', function() {
  return gulp.src('./_build/**')
    .pipe(confirm('Make sure everything looks right before you deploy.'))
    .pipe(rsync({
      root: './_build',
      hostname: 'deployer@72.32.134.77',
      destination: '/home/deployer/sites/scalingsexiness/foundation-sites-6-docs'
    }));
}));



// This part of the deploy process hasn't been tested! It should be done manually for now
gulp.task('deploy:templates', function(done) {
  // exec('git clone https://github.com/zurb/foundation-sites-template');
  // exec('cp scss/settings/_settings.scss foundation-sites-template/scss/_settings.scss');
  // exec('cd foundation-sites-template');
  // exec('git commit -am "Update settings file to match Foundation "' + NEXT_VERSION);
  // exec('git push origin master');
  // exec('cd ..');
  // exec('rm -rf foundation-sites-template');
  //
  // exec('git clone https://github.com/zurb/foundation-zurb-template');
  // exec('cp scss/settings/_settings.scss foundation-zurb-template/src/assets/scss/_settings.scss');
  // exec('cd foundation-zurb-template');
  // exec('git commit -am "Update settings file to match Foundation "' + NEXT_VERSION);
  // exec('git push origin master');
  // exec('cd ..');
  // exec('rm -rf foundation-zurb-template');
  done();
});

// The Customizer runs this function to generate files it needs
gulp.task('deploy:custom', gulp.series('sass:foundation', 'javascript:foundation', gulp.parallel(
  function () {
    return gulp.src('./_build/assets/css/foundation.css')
      .pipe(cleancss({ compatibility: 'ie9' }))
      .pipe(rename('foundation.min.css'))
      .pipe(gulp.dest('./_build/assets/css'));
  },
  function () {
    return gulp.src('_build/assets/js/foundation.js')
      .pipe(uglify())
      .pipe(rename('foundation.min.js'))
      .pipe(gulp.dest('./_build/assets/js'));
  }
)));
