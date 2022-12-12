module.exports = {

  // Javascript
  JS_BUNDLE_NAMESPACE: '__FOUNDATION_EXTERNAL__',

  JS_FILES: [
    'js/foundation.core.js',
    'js/foundation.core.utils.js',
    'js/foundation.util.*.js',
    'js/*.js'
  ],

  JS_DEPS: [
    'node_modules/jquery/dist/jquery.js',
    'node_modules/motion-ui/dist/motion-ui.js',
    'node_modules/what-input/dist/what-input.js'
  ],

  JS_DOCS: [
    'node_modules/clipboard/dist/clipboard.js',
    'node_modules/corejs-typeahead/dist/typeahead.bundle.js',
    'node_modules/foundation-docs/js/**/*.js',
    'docs/assets/js/docs.*.js',
    'docs/assets/js/docs.js'
  ],

  // Sass
  SASS_DEPS_FILES: [
    'node_modules/@(sassy-lists)/stylesheets/helpers/_missing-dependencies.scss',
    'node_modules/@(sassy-lists)/stylesheets/helpers/_true.scss',
    'node_modules/@(sassy-lists)/stylesheets/functions/_contain.scss',
    'node_modules/@(sassy-lists)/stylesheets/functions/_purge.scss',
    'node_modules/@(sassy-lists)/stylesheets/functions/_remove.scss',
    'node_modules/@(sassy-lists)/stylesheets/functions/_replace.scss',
    'node_modules/@(sassy-lists)/stylesheets/functions/_to-list.scss'
  ],

  SASS_DOC_PATHS: [
    'scss',
    'node_modules/motion-ui/src',
    'node_modules/foundation-docs/scss'
  ],

  SASS_LINT_FILES: [
    'scss/**/*.scss',
  ],

  // Assets
  ASSETS_FILES: [
    'docs/assets/**/*',
    '!docs/assets/{js,scss}',
    '!docs/assets/{js,scss}/**/*'
  ],

  // Dist
  VERSIONED_FILES: [
    'bower.json',
    'composer.json',
    'docs/pages/installation.md',
    'js/foundation.core.js',
    'meteor-README.md',
    'package.js',
    'package.json',
    'scss/foundation.scss'
  ],

  DIST_FILES: [
    './_build/assets/css/foundation.css',
    './_build/assets/css/foundation.css.map',
    './_build/assets/css/foundation-float.css',
    './_build/assets/css/foundation-float.css.map',
    './_build/assets/css/foundation-prototype.css',
    './_build/assets/css/foundation-prototype.css.map',
    './_build/assets/css/foundation-rtl.css',
    './_build/assets/css/foundation-rtl.css.map',
    '_build/assets/js/foundation.js',
    '_build/assets/js/foundation.js.map',
    'js/typescript/foundation.d.ts'
  ],

  // Tests
  TEST_JS_FILES: [
    'test/javascript/core/**/*.js',
    'test/javascript/util/**/*.js',
    'test/javascript/components/**/*.js'
  ]
};
