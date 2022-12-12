import path from 'path';
import { sync as findUpSync } from 'find-up';
export var findDistEsm = function (cwd, relativePath) {
  var packageDir = path.dirname(findUpSync('package.json', {
    cwd: cwd
  }));
  return path.join(packageDir, 'dist', 'esm', relativePath);
};