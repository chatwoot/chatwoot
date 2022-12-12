"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getMiddleware = getMiddleware;

var _path = _interopRequireDefault(require("path"));

var _fs = _interopRequireDefault(require("fs"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var fileExists = function (basename) {
  return ['.js', '.cjs'].reduce(function (found, ext) {
    var filename = `${basename}${ext}`;
    return !found && _fs.default.existsSync(filename) ? filename : found;
  }, '');
};

function getMiddleware(configDir) {
  var middlewarePath = fileExists(_path.default.resolve(configDir, 'middleware'));

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