"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _parserBabel = _interopRequireDefault(require("prettier/parser-babel"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function parse(source) {
  try {
    return _parserBabel.default.parsers.babel.parse(source);
  } catch (error1) {
    try {
      return JSON.stringify(source);
    } catch (error) {
      throw error1;
    }
  }
}

function format(source) {
  return _parserBabel.default.parsers.babel.format(source);
}

var _default = {
  parse: parse,
  format: format
};
exports.default = _default;