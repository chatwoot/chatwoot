import path from 'path';
import fs from 'fs';

var fileExists = function (basename) {
  return ['.js', '.cjs'].reduce(function (found, ext) {
    var filename = `${basename}${ext}`;
    return !found && fs.existsSync(filename) ? filename : found;
  }, '');
};

export function getMiddleware(configDir) {
  var middlewarePath = fileExists(path.resolve(configDir, 'middleware'));

  if (middlewarePath) {
    var middlewareModule = require(middlewarePath); // eslint-disable-line


    if (middlewareModule.__esModule) {
      // eslint-disable-line
      middlewareModule = middlewareModule.default;
    }

    return middlewareModule;
  }

  return function () {};
}