import path from 'path';
import pkgDir from 'pkg-dir';
/**
 * Get the path of the file or directory with input name inside the Storybook cache directory:
 *  - `node_modules/.cache/storybook/{directoryName}` in a Node.js project or npm package
 *  - `.cache/storybook/{directoryName}` otherwise
 *
 * @param fileOrDirectoryName {string} Name of the file or directory
 * @return {string} Absolute path to the file or directory
 */

export function resolvePathInStorybookCache(fileOrDirectoryName) {
  var cwd = process.cwd();
  var projectDir = pkgDir.sync(cwd);
  var cacheDirectory;

  if (!projectDir) {
    cacheDirectory = path.resolve(cwd, '.cache/storybook');
  } else {
    cacheDirectory = path.resolve(projectDir, 'node_modules/.cache/storybook');
  }

  return path.join(cacheDirectory, fileOrDirectoryName);
}