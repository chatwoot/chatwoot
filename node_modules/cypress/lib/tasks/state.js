"use strict";

var _ = require('lodash');

var os = require('os');

var path = require('path');

var untildify = require('untildify');

var debug = require('debug')('cypress:cli');

var fs = require('../fs');

var util = require('../util');

var getPlatformExecutable = function getPlatformExecutable() {
  var platform = os.platform();

  switch (platform) {
    case 'darwin':
      return 'Contents/MacOS/Cypress';

    case 'linux':
      return 'Cypress';

    case 'win32':
      return 'Cypress.exe';
    // TODO handle this error using our standard

    default:
      throw new Error("Platform: \"".concat(platform, "\" is not supported."));
  }
};

var getPlatFormBinaryFolder = function getPlatFormBinaryFolder() {
  var platform = os.platform();

  switch (platform) {
    case 'darwin':
      return 'Cypress.app';

    case 'linux':
      return 'Cypress';

    case 'win32':
      return 'Cypress';
    // TODO handle this error using our standard

    default:
      throw new Error("Platform: \"".concat(platform, "\" is not supported."));
  }
};

var getBinaryPkgPath = function getBinaryPkgPath(binaryDir) {
  var platform = os.platform();

  switch (platform) {
    case 'darwin':
      return path.join(binaryDir, 'Contents', 'Resources', 'app', 'package.json');

    case 'linux':
      return path.join(binaryDir, 'resources', 'app', 'package.json');

    case 'win32':
      return path.join(binaryDir, 'resources', 'app', 'package.json');
    // TODO handle this error using our standard

    default:
      throw new Error("Platform: \"".concat(platform, "\" is not supported."));
  }
};
/**
 * Get path to binary directory
*/


var getBinaryDir = function getBinaryDir() {
  var version = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : util.pkgVersion();
  return path.join(getVersionDir(version), getPlatFormBinaryFolder());
};

var getVersionDir = function getVersionDir() {
  var version = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : util.pkgVersion();
  return path.join(getCacheDir(), version);
};
/**
 * When executing "npm postinstall" hook, the working directory is set to
 * "<current folder>/node_modules/cypress", which can be surprising when using relative paths.
 */


var isInstallingFromPostinstallHook = function isInstallingFromPostinstallHook() {
  // individual folders
  var cwdFolders = process.cwd().split(path.sep);
  var length = cwdFolders.length;
  return cwdFolders[length - 2] === 'node_modules' && cwdFolders[length - 1] === 'cypress';
};

var getCacheDir = function getCacheDir() {
  var cache_directory = util.getCacheDir();

  if (util.getEnv('CYPRESS_CACHE_FOLDER')) {
    var envVarCacheDir = untildify(util.getEnv('CYPRESS_CACHE_FOLDER'));
    debug('using environment variable CYPRESS_CACHE_FOLDER %s', envVarCacheDir);

    if (!path.isAbsolute(envVarCacheDir) && isInstallingFromPostinstallHook()) {
      var packageRootFolder = path.join('..', '..', envVarCacheDir);
      cache_directory = path.resolve(packageRootFolder);
      debug('installing from postinstall hook, original root folder is %s', packageRootFolder);
      debug('and resolved cache directory is %s', cache_directory);
    } else {
      cache_directory = path.resolve(envVarCacheDir);
    }
  }

  return cache_directory;
};

var parseRealPlatformBinaryFolderAsync = function parseRealPlatformBinaryFolderAsync(binaryPath) {
  return fs.realpathAsync(binaryPath).then(function (realPath) {
    debug('CYPRESS_RUN_BINARY has realpath:', realPath);

    if (!realPath.toString().endsWith(getPlatformExecutable())) {
      return false;
    }

    if (os.platform() === 'darwin') {
      return path.resolve(realPath, '..', '..', '..');
    }

    return path.resolve(realPath, '..');
  });
};

var getDistDir = function getDistDir() {
  return path.join(__dirname, '..', '..', 'dist');
};
/**
 * Returns full filename to the file that keeps the Test Runner verification state as JSON text.
 * Note: the binary state file will be stored one level up from the given binary folder.
 * @param {string} binaryDir - full path to the folder holding the binary.
 */


var getBinaryStatePath = function getBinaryStatePath(binaryDir) {
  return path.join(binaryDir, '..', 'binary_state.json');
};

var getBinaryStateContentsAsync = function getBinaryStateContentsAsync(binaryDir) {
  var fullPath = getBinaryStatePath(binaryDir);
  return fs.readJsonAsync(fullPath)["catch"]({
    code: 'ENOENT'
  }, SyntaxError, function () {
    debug('could not read binary_state.json file at "%s"', fullPath);
    return {};
  });
};

var getBinaryVerifiedAsync = function getBinaryVerifiedAsync(binaryDir) {
  return getBinaryStateContentsAsync(binaryDir).tap(debug).get('verified');
};

var clearBinaryStateAsync = function clearBinaryStateAsync(binaryDir) {
  return fs.removeAsync(getBinaryStatePath(binaryDir));
};
/**
 * Writes the new binary status.
 * @param {boolean} verified The new test runner state after smoke test
 * @param {string} binaryDir Folder holding the binary
 * @returns {Promise<void>} returns a promise
 */


var writeBinaryVerifiedAsync = function writeBinaryVerifiedAsync(verified, binaryDir) {
  return getBinaryStateContentsAsync(binaryDir).then(function (contents) {
    return fs.outputJsonAsync(getBinaryStatePath(binaryDir), _.extend(contents, {
      verified: verified
    }), {
      spaces: 2
    });
  });
};

var getPathToExecutable = function getPathToExecutable(binaryDir) {
  return path.join(binaryDir, getPlatformExecutable());
};

var getBinaryPkgVersionAsync = function getBinaryPkgVersionAsync(binaryDir) {
  var pathToPackageJson = getBinaryPkgPath(binaryDir);
  debug('Reading binary package.json from:', pathToPackageJson);
  return fs.pathExistsAsync(pathToPackageJson).then(function (exists) {
    if (!exists) {
      return null;
    }

    return fs.readJsonAsync(pathToPackageJson).get('version');
  });
};

module.exports = {
  getPathToExecutable: getPathToExecutable,
  getPlatformExecutable: getPlatformExecutable,
  getBinaryPkgVersionAsync: getBinaryPkgVersionAsync,
  getBinaryVerifiedAsync: getBinaryVerifiedAsync,
  getBinaryPkgPath: getBinaryPkgPath,
  getBinaryDir: getBinaryDir,
  getCacheDir: getCacheDir,
  clearBinaryStateAsync: clearBinaryStateAsync,
  writeBinaryVerifiedAsync: writeBinaryVerifiedAsync,
  parseRealPlatformBinaryFolderAsync: parseRealPlatformBinaryFolderAsync,
  getDistDir: getDistDir,
  getVersionDir: getVersionDir
};