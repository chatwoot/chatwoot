"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _helperPluginUtils = require("@babel/helper-plugin-utils");

var _pluginSyntaxNumericSeparator = _interopRequireDefault(require("@babel/plugin-syntax-numeric-separator"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function remover({
  node
}) {
  var _extra$raw;

  const {
    extra
  } = node;

  if (extra == null ? void 0 : (_extra$raw = extra.raw) == null ? void 0 : _extra$raw.includes("_")) {
    extra.raw = extra.raw.replace(/_/g, "");
  }
}

var _default = (0, _helperPluginUtils.declare)(api => {
  api.assertVersion(7);
  return {
    name: "proposal-numeric-separator",
    inherits: _pluginSyntaxNumericSeparator.default,
    visitor: {
      NumericLiteral: remover,
      BigIntLiteral: remover
    }
  };
});

exports.default = _default;