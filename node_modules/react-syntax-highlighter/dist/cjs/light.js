"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _highlight = _interopRequireDefault(require("./highlight"));

var _core = _interopRequireDefault(require("lowlight/lib/core"));

var SyntaxHighlighter = (0, _highlight["default"])(_core["default"], {});
SyntaxHighlighter.registerLanguage = _core["default"].registerLanguage;
var _default = SyntaxHighlighter;
exports["default"] = _default;