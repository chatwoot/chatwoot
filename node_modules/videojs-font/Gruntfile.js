require('babel-register');

module.exports = function(grunt) {
  require('time-grunt')(grunt);
  require('load-grunt-tasks')(grunt);

  require('./lib/grunt.js')(grunt);
};
