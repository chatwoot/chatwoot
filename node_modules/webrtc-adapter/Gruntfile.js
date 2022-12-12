'use strict';

module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    babel: {
      options: {
        presets: ['babel-preset-env']
      },
      dist: {
        files: [{
          expand: 'true',
          cwd: 'src/js',
          src: ['*.js', '**/*.js'],
          dest: 'dist/'
        }]
      }
    },
    browserify: {
      adapterGlobalObject: {
        src: ['./dist/adapter_core5.js'],
        dest: './out/adapter.js',
        options: {
          browserifyOptions: {
            // Exposes shim methods in a global object to the browser.
            // The tests require this.
            standalone: 'adapter'
          }
        }
      },
      // Use this if you do not want adapter to expose anything to the global
      // scope.
      adapterAndNoGlobalObject: {
        src: ['./dist/adapter_core5.js'],
        dest: './out/adapter_no_global.js'
      }
    },
    eslint: {
      options: {
        configFile: '.eslintrc'
      },
      target: ['src/**/*.js', 'test/*.js', 'test/unit/*.js', 'test/e2e/*.js']
    },
    copy: {
      build: {
        dest: 'release/',
        cwd: 'out',
        src: '**',
        nonull: true,
        expand: true
      }
    },
    shell: {
      downloadBrowser : {
        command: 'BROWSER=${BROWSER-chrome} BVER=${BVER-stable} ./node_modules/travis-multirunner/setup.sh'
      },
    },
  });

  grunt.loadNpmTasks('grunt-eslint');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-babel');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-shell');

  grunt.registerTask('default', ['eslint', 'build']);
  grunt.registerTask('lint', ['eslint']);
  grunt.registerTask('build', ['babel', 'browserify']);
  grunt.registerTask('copyForPublish', ['copy']);
  grunt.registerTask('downloadBrowser', ['shell:downloadBrowser'])
};
