"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.nodePathsToArray = exports.getProjectRoot = void 0;
exports.normalizeStoryPath = normalizeStoryPath;

var _path = _interopRequireDefault(require("path"));

var _findUp = _interopRequireDefault(require("find-up"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getProjectRoot = function () {
  var result;

  try {
    result = result || _path.default.join(_findUp.default.sync('.git', {
      type: 'directory'
    }), '..');
  } catch (e) {//
  }

  try {
    result = result || _path.default.join(_findUp.default.sync('.svn', {
      type: 'directory'
    }), '..');
  } catch (e) {//
  }

  try {
    result = result || __dirname.split('node_modules')[0];
  } catch (e) {//
  }

  return result || process.cwd();
};

exports.getProjectRoot = getProjectRoot;

var nodePathsToArray = function (nodePath) {
  return nodePath.split(process.platform === 'win32' ? ';' : ':').filter(Boolean).map(function (p) {
    return _path.default.resolve('./', p);
  });
};

exports.nodePathsToArray = nodePathsToArray;
var relativePattern = /^\.{1,2}([/\\]|$)/;
/**
 * Ensures that a path starts with `./` or `../`, or is entirely `.` or `..`
 */

function normalizeStoryPath(filename) {
  if (relativePattern.test(filename)) return filename;
  return `.${_path.default.sep}${filename}`;
}