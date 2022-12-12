"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = escapeClassName;

var _postcssSelectorParser = _interopRequireDefault(require("postcss-selector-parser"));

var _get = _interopRequireDefault(require("lodash/get"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function escapeClassName(className) {
  const node = _postcssSelectorParser.default.className();

  node.value = className;
  return (0, _get.default)(node, 'raws.value', node.value);
}