"use strict";

var debug = require('debug')('cypress:cli');

var util = require('../util');

var spawn = require('./spawn');

var verify = require('../tasks/verify');

module.exports = {
  start: function start() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

    if (!util.isInstalledGlobally() && !options.global && !options.project) {
      options.project = process.cwd();
    }

    var args = [];

    if (options.config) {
      args.push('--config', options.config);
    }

    if (options.configFile !== undefined) {
      args.push('--config-file', options.configFile);
    }

    if (options.browser) {
      args.push('--browser', options.browser);
    }

    if (options.env) {
      args.push('--env', options.env);
    }

    if (options.port) {
      args.push('--port', options.port);
    }

    if (options.project) {
      args.push('--project', options.project);
    }

    debug('opening from options %j', options);
    debug('command line arguments %j', args);

    function open() {
      return spawn.start(args, {
        dev: options.dev,
        detached: Boolean(options.detached),
        stdio: 'inherit'
      });
    }

    if (options.dev) {
      return open();
    }

    return verify.start().then(open);
  }
};