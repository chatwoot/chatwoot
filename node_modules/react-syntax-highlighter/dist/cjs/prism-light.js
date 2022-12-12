"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _highlight = _interopRequireDefault(require("./highlight"));

var _core = _interopRequireDefault(require("refractor/core"));

var SyntaxHighlighter = (0, _highlight["default"])(_core["default"], {});

SyntaxHighlighter.registerLanguage = function (_, language) {
  return _core["default"].register(language);
};

SyntaxHighlighter.alias = function (name, aliases) {
  return _core["default"].alias(name, aliases);
};

var _default = SyntaxHighlighter;
exports["default"] = _default;