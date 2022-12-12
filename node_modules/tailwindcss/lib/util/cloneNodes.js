"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = cloneNodes;

var _lodash = _interopRequireDefault(require("lodash"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function cloneNodes(nodes) {
  return _lodash.default.map(nodes, node => node.clone());
}