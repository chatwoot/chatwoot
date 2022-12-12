"use strict";

var Promise = require('bluebird');

var debug = require('debug')('cypress:cli');

var path = require('path');

var util = require('../util');

var state = require('../tasks/state');

var _require = require('../errors'),
    throwFormErrorText = _require.throwFormErrorText,
    errors = _require.errors;

var getVersions = function getVersions() {
  return Promise["try"](function () {
    if (util.getEnv('CYPRESS_RUN_BINARY')) {
      var envBinaryPath = path.resolve(util.getEnv('CYPRESS_RUN_BINARY'));
      return state.parseRealPlatformBinaryFolderAsync(envBinaryPath).then(function (envBinaryDir) {
        if (!envBinaryDir) {
          return throwFormErrorText(errors.CYPRESS_RUN_BINARY.notValid(envBinaryPath))();
        }

        debug('CYPRESS_RUN_BINARY has binaryDir:', envBinaryDir);
        return envBinaryDir;
      })["catch"]({
        code: 'ENOENT'
      }, function (err) {
        return throwFormErrorText(errors.CYPRESS_RUN_BINARY.notValid(envBinaryPath))(err.message);
      });
    }

    return state.getBinaryDir();
  }).then(state.getBinaryPkgVersionAsync).then(function (binaryVersion) {
    return {
      "package": util.pkgVersion(),
      binary: binaryVersion || 'not installed'
    };
  });
};

module.exports = {
  getVersions: getVersions
};