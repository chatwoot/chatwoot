import path from 'path';
import findUp from 'find-up';
export var getProjectRoot = function () {
  var result;

  try {
    result = result || path.join(findUp.sync('.git', {
      type: 'directory'
    }), '..');
  } catch (e) {//
  }

  try {
    result = result || path.join(findUp.sync('.svn', {
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
export var nodePathsToArray = function (nodePath) {
  return nodePath.split(process.platform === 'win32' ? ';' : ':').filter(Boolean).map(function (p) {
    return path.resolve('./', p);
  });
};
var relativePattern = /^\.{1,2}([/\\]|$)/;
/**
 * Ensures that a path starts with `./` or `../`, or is entirely `.` or `..`
 */

export function normalizeStoryPath(filename) {
  if (relativePattern.test(filename)) return filename;
  return `.${path.sep}${filename}`;
}