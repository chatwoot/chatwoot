"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.resolvePathInStorybookCache = resolvePathInStorybookCache;

var _path = _interopRequireDefault(require("path"));

var _pkgDir = _interopRequireDefault(require("pkg-dir"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Get the path of the file or directory with input name inside the Storybook cache directory:
 *  - `node_modules/.cache/storybook/{directoryName}` in a Node.js project or npm package
 *  - `.cache/storybook/{directoryName}` otherwise
 *
 * @param fileOrDirectoryName {string} Name of the file or directory
 * @return {string} Absolute path to the file or directory
 */
function resolvePathInStorybookCache(fileOrDirectoryName) {
  var cwd = process.cwd();

  var projectDir = _pkgDir.default.sync(cwd);

  var cacheDirectory;

  if (!projectDir) {
    cacheDirectory = _path.default.resolve(cwd, '.cache/storybook');
  } else {
    cacheDirectory = _path.default.resolve(projectDir, 'node_modules/.cache/storybook');
  }

  return _path.default.join(cacheDirectory, fileOrDirectoryName);
}