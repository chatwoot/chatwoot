"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

require("core-js/modules/es.regexp.exec.js");

var _parserJs = _interopRequireDefault(require("./parser-js"));

var _parserTs = _interopRequireDefault(require("./parser-ts"));

var _parserFlow = _interopRequireDefault(require("./parser-flow"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getParser(type) {
  if (type === 'javascript' || /\.jsx?/.test(type) || !type) {
    return _parserJs.default;
  }

  if (type === 'typescript' || /\.tsx?/.test(type)) {
    return _parserTs.default;
  }

  if (type === 'flow') {
    return _parserFlow.default;
  }

  throw new Error("Parser of type \"".concat(type, "\" is not supported"));
}

var _default = getParser;
exports.default = _default;