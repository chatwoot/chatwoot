"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createUpdateMessage = createUpdateMessage;
exports.updateCheck = void 0;

require("core-js/modules/es.promise.js");

var _nodeFetch = _interopRequireDefault(require("node-fetch"));

var _chalk = _interopRequireDefault(require("chalk"));

var _nodeLogger = require("@storybook/node-logger");

var _semver = _interopRequireDefault(require("@storybook/semver"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _coreCommon = require("@storybook/core-common");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _process$env = process.env,
    _process$env$STORYBOO = _process$env.STORYBOOK_VERSION_BASE,
    STORYBOOK_VERSION_BASE = _process$env$STORYBOO === void 0 ? 'https://storybook.js.org' : _process$env$STORYBOO,
    CI = _process$env.CI;

var updateCheck = async function (version) {
  var result;
  var time = Date.now();

  try {
    var fromCache = await _coreCommon.cache.get('lastUpdateCheck', {
      success: false,
      time: 0
    }); // if last check was more then 24h ago

    if (time - 86400000 > fromCache.time && !CI) {
      var fromFetch = await Promise.race([(0, _nodeFetch.default)(`${STORYBOOK_VERSION_BASE}/versions.json?current=${version}`), // if fetch is too slow, we won't wait for it
      new Promise(function (res, rej) {
        return global.setTimeout(rej, 1500);
      })]);
      var data = await fromFetch.json();
      result = {
        success: true,
        data: data,
        time: time
      };
      await _coreCommon.cache.set('lastUpdateCheck', result);
    } else {
      result = fromCache;
    }
  } catch (error) {
    result = {
      success: false,
      error: error,
      time: time
    };
  }

  return result;
};

exports.updateCheck = updateCheck;

function createUpdateMessage(updateInfo, version) {
  var updateMessage;

  try {
    var suffix = _semver.default.prerelease(updateInfo.data.latest.version) ? '--prerelease' : '';
    var upgradeCommand = `npx storybook@latest upgrade ${suffix}`.trim();
    updateMessage = updateInfo.success && _semver.default.lt(version, updateInfo.data.latest.version) ? (0, _tsDedent.default)`
          ${_nodeLogger.colors.orange(`A new version (${_chalk.default.bold(updateInfo.data.latest.version)}) is available!`)}

          ${_chalk.default.gray('Upgrade now:')} ${_nodeLogger.colors.green(upgradeCommand)}

          ${_chalk.default.gray('Read full changelog:')} ${_chalk.default.gray.underline('https://github.com/storybookjs/storybook/blob/next/CHANGELOG.md')}
        ` : '';
  } catch (e) {
    updateMessage = '';
  }

  return updateMessage;
}