"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _parserFlow = _interopRequireDefault(require("prettier/parser-flow"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function parse(source) {
  return _parserFlow.default.parsers.flow.parse(source);
}

function format(source) {
  return _parserFlow.default.parsers.flow.format(source);
}

var _default = {
  parse: parse,
  format: format
};
exports.default = _default;