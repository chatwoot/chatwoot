"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.findDistEsm = void 0;

var _path = _interopRequireDefault(require("path"));

var _findUp = require("find-up");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var findDistEsm = function (cwd, relativePath) {
  var packageDir = _path.default.dirname((0, _findUp.sync)('package.json', {
    cwd: cwd
  }));

  return _path.default.join(packageDir, 'dist', 'esm', relativePath);
};

exports.findDistEsm = findDistEsm;