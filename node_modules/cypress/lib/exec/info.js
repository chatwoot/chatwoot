"use strict";

/* eslint-disable no-console */
var spawn = require('./spawn');

var util = require('../util');

var state = require('../tasks/state');

var os = require('os');

var chalk = require('chalk');

var prettyBytes = require('pretty-bytes');

var _ = require('lodash');

var R = require('ramda'); // color for numbers and show values


var g = chalk.green; // color for paths

var p = chalk.cyan; // urls

var link = chalk.blue.underline; // to be exported

var methods = {};

methods.findProxyEnvironmentVariables = function () {
  return _.pick(process.env, ['HTTP_PROXY', 'HTTPS_PROXY', 'NO_PROXY']);
};

var maskSensitiveVariables = R.evolve({
  CYPRESS_RECORD_KEY: R.always('<redacted>')
});

methods.findCypressEnvironmentVariables = function () {
  var isCyVariable = function isCyVariable(val, key) {
    return key.startsWith('CYPRESS_');
  };

  return R.pickBy(isCyVariable)(process.env);
};

var formatCypressVariables = function formatCypressVariables() {
  var vars = methods.findCypressEnvironmentVariables();
  return maskSensitiveVariables(vars);
};

methods.start = function () {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var args = ['--mode=info'];
  return spawn.start(args, {
    dev: options.dev
  }).then(function () {
    console.log();
    var proxyVars = methods.findProxyEnvironmentVariables();

    if (_.isEmpty(proxyVars)) {
      console.log('Proxy Settings: none detected');
    } else {
      console.log('Proxy Settings:');

      _.forEach(proxyVars, function (value, key) {
        console.log('%s: %s', key, g(value));
      });

      console.log();
      console.log('Learn More: %s', link('https://on.cypress.io/proxy-configuration'));
      console.log();
    }
  }).then(function () {
    var cyVars = formatCypressVariables();

    if (_.isEmpty(cyVars)) {
      console.log('Environment Variables: none detected');
    } else {
      console.log('Environment Variables:');

      _.forEach(cyVars, function (value, key) {
        console.log('%s: %s', key, g(value));
      });
    }
  }).then(function () {
    console.log();
    console.log('Application Data:', p(util.getApplicationDataFolder()));
    console.log('Browser Profiles:', p(util.getApplicationDataFolder('browsers')));
    console.log('Binary Caches: %s', p(state.getCacheDir()));
  }).then(function () {
    console.log();
    return util.getOsVersionAsync().then(function (osVersion) {
      console.log('Cypress Version: %s', g(util.pkgVersion()));
      console.log('System Platform: %s (%s)', g(os.platform()), g(osVersion));
      console.log('System Memory: %s free %s', g(prettyBytes(os.totalmem())), g(prettyBytes(os.freemem())));
    });
  });
};

module.exports = methods;