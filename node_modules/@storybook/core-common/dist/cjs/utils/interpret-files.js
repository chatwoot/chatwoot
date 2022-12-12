"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.boost = void 0;
exports.getInterpretedFile = getInterpretedFile;
exports.getInterpretedFileWithExt = getInterpretedFileWithExt;

require("core-js/modules/es.array.sort.js");

var _fs = _interopRequireDefault(require("fs"));

var _interpret = require("interpret");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var boost = new Set(['.js', '.jsx', '.ts', '.tsx', '.cjs', '.mjs']);
exports.boost = boost;

function sortExtensions() {
  return [...Array.from(boost), ...Object.keys(_interpret.extensions).filter(function (ext) {
    return !boost.has(ext);
  }).sort(function (a, b) {
    return a.length - b.length;
  })];
}

var possibleExtensions = sortExtensions();

function getInterpretedFile(pathToFile) {
  return possibleExtensions.map(function (ext) {
    return pathToFile.endsWith(ext) ? pathToFile : `${pathToFile}${ext}`;
  }).find(function (candidate) {
    return _fs.default.existsSync(candidate);
  });
}

function getInterpretedFileWithExt(pathToFile) {
  return possibleExtensions.map(function (ext) {
    return {
      path: pathToFile.endsWith(ext) ? pathToFile : `${pathToFile}${ext}`,
      ext: ext
    };
  }).find(function (candidate) {
    return _fs.default.existsSync(candidate.path);
  });
}