"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _highlight = _interopRequireDefault(require("./highlight"));

var _defaultStyle = _interopRequireDefault(require("./styles/hljs/default-style"));

var _lowlight = _interopRequireDefault(require("lowlight"));

var _supportedLanguages = _interopRequireDefault(require("./languages/hljs/supported-languages"));

var highlighter = (0, _highlight["default"])(_lowlight["default"], _defaultStyle["default"]);
highlighter.supportedLanguages = _supportedLanguages["default"];
var _default = highlighter;
exports["default"] = _default;