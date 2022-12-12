"use strict";

function _templateObject() {
  var data = _taggedTemplateLiteral(["\n        DISPLAY environment variable is set to ", " on Linux\n        Assuming this DISPLAY points at working X11 server,\n        Cypress will not spawn own Xvfb\n\n        NOTE: if the X11 server is NOT working, Cypress will exit without explanation,\n          see ", "\n        Solution: Unset the DISPLAY variable and try again:\n          DISPLAY= npx cypress run ...\n      "]);

  _templateObject = function _templateObject() {
    return data;
  };

  return data;
}

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var os = require('os');

var Promise = require('bluebird');

var Xvfb = require('@cypress/xvfb');

var _require = require('common-tags'),
    stripIndent = _require.stripIndent;

var debug = require('debug')('cypress:cli');

var debugXvfb = require('debug')('cypress:xvfb');

var _require2 = require('../errors'),
    throwFormErrorText = _require2.throwFormErrorText,
    errors = _require2.errors;

var util = require('../util');

var xvfbOptions = {
  timeout: 30000,
  // milliseconds
  // need to explicitly define screen otherwise electron will crash
  // https://github.com/cypress-io/cypress/issues/6184
  xvfb_args: ['-screen', '0', '1280x1024x24'],
  onStderrData: function onStderrData(data) {
    if (debugXvfb.enabled) {
      debugXvfb(data.toString());
    }
  }
};
var xvfb = Promise.promisifyAll(new Xvfb(xvfbOptions));
module.exports = {
  _debugXvfb: debugXvfb,
  // expose for testing
  _xvfb: xvfb,
  // expose for testing
  _xvfbOptions: xvfbOptions,
  // expose for testing
  start: function start() {
    debug('Starting Xvfb');
    return xvfb.startAsync()["return"](null)["catch"]({
      nonZeroExitCode: true
    }, throwFormErrorText(errors.nonZeroExitCodeXvfb))["catch"](function (err) {
      if (err.known) {
        throw err;
      }

      return throwFormErrorText(errors.missingXvfb)(err);
    });
  },
  stop: function stop() {
    debug('Stopping Xvfb');
    return xvfb.stopAsync()["return"](null)["catch"](function () {// noop
    });
  },
  isNeeded: function isNeeded() {
    if (os.platform() !== 'linux') {
      return false;
    }

    if (process.env.DISPLAY) {
      var issueUrl = util.getGitHubIssueUrl(4034);
      var message = stripIndent(_templateObject(), process.env.DISPLAY, issueUrl);
      debug(message);
      return false;
    }

    debug('undefined DISPLAY environment variable');
    debug('Cypress will spawn its own Xvfb');
    return true;
  },
  // async method, resolved with Boolean
  verify: function verify() {
    return xvfb.startAsync()["return"](true)["catch"](function (err) {
      debug('Could not verify xvfb: %s', err.message);
      return false;
    })["finally"](xvfb.stopAsync);
  }
};