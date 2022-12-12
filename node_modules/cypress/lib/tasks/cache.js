"use strict";

var state = require('./state');

var logger = require('../logger');

var fs = require('../fs');

var util = require('../util');

var _require = require('path'),
    join = _require.join;

var Table = require('cli-table3');

var moment = require('moment');

var chalk = require('chalk');

var _ = require('lodash'); // output colors for the table


var colors = {
  titles: chalk.white,
  dates: chalk.cyan,
  values: chalk.green
};

var logCachePath = function logCachePath() {
  logger.always(state.getCacheDir());
  return undefined;
};

var clear = function clear() {
  return fs.removeAsync(state.getCacheDir());
};
/**
 * Collects all cached versions, finds when each was used
 * and prints a table with results to the terminal
 */


var list = function list() {
  return getCachedVersions().then(function (binaries) {
    var table = new Table({
      head: [colors.titles('version'), colors.titles('last used')]
    });
    binaries.forEach(function (binary) {
      var versionString = colors.values(binary.version);
      var lastUsed = binary.accessed ? colors.dates(binary.accessed) : 'unknown';
      return table.push([versionString, lastUsed]);
    });
    logger.always(table.toString());
  });
};

var getCachedVersions = function getCachedVersions() {
  var cacheDir = state.getCacheDir();
  return fs.readdirAsync(cacheDir).filter(util.isSemver).map(function (version) {
    return {
      version: version,
      folderPath: join(cacheDir, version)
    };
  }).mapSeries(function (binary) {
    // last access time on the folder is different from last access time
    // on the Cypress binary
    var binaryDir = state.getBinaryDir(binary.version);
    var executable = state.getPathToExecutable(binaryDir);
    return fs.statAsync(executable).then(function (stat) {
      var lastAccessedTime = _.get(stat, 'atime');

      if (!lastAccessedTime) {
        // the test runner has never been opened
        // or could be a test simulating missing timestamp
        return binary;
      }

      var accessed = moment(lastAccessedTime).fromNow();
      binary.accessed = accessed;
      return binary;
    }, function (e) {
      // could not find the binary or gets its stats
      return binary;
    });
  });
};

module.exports = {
  path: logCachePath,
  clear: clear,
  list: list,
  getCachedVersions: getCachedVersions
};