"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _createPlugin = _interopRequireDefault(require("./create-plugin"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = (0, _createPlugin.default)({
  name: "transform-react-jsx",
  development: false
});

exports.default = _default;