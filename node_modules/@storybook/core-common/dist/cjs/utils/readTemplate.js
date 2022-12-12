"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.readTemplate = readTemplate;

require("core-js/modules/es.promise.js");

var _fsExtra = _interopRequireDefault(require("fs-extra"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

async function readTemplate(filename) {
  return _fsExtra.default.readFile(filename, {
    encoding: 'utf8'
  });
}