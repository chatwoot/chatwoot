"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DocsPage = void 0;

var _react = _interopRequireDefault(require("react"));

var _Title = require("./Title");

var _Subtitle = require("./Subtitle");

var _Description = require("./Description");

var _Primary = require("./Primary");

var _types = require("./types");

var _ArgsTable = require("./ArgsTable");

var _Stories = require("./Stories");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DocsPage = function DocsPage() {
  return /*#__PURE__*/_react.default.createElement(_react.default.Fragment, null, /*#__PURE__*/_react.default.createElement(_Title.Title, null), /*#__PURE__*/_react.default.createElement(_Subtitle.Subtitle, null), /*#__PURE__*/_react.default.createElement(_Description.Description, null), /*#__PURE__*/_react.default.createElement(_Primary.Primary, null), /*#__PURE__*/_react.default.createElement(_ArgsTable.ArgsTable, {
    story: _types.PRIMARY_STORY
  }), /*#__PURE__*/_react.default.createElement(_Stories.Stories, null));
};

exports.DocsPage = DocsPage;