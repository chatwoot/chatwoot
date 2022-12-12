"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _parserTypescript = _interopRequireDefault(require("prettier/parser-typescript"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function parse(source) {
  try {
    return _parserTypescript.default.parsers.typescript.parse(source);
  } catch (error1) {
    try {
      return JSON.stringify(source);
    } catch (error) {
      throw error1;
    }
  }
}

function format(source) {
  return _parserTypescript.default.parsers.typescript.format(source);
}

var _default = {
  parse: parse,
  format: format
};
exports.default = _default;