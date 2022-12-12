"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.NoDocs = void 0;

var _react = _interopRequireDefault(require("react"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var wrapper = {
  fontSize: '14px',
  letterSpacing: '0.2px',
  margin: '10px 0'
};
var main = {
  margin: 'auto',
  padding: 30,
  borderRadius: 10,
  background: 'rgba(0,0,0,0.03)'
};
var heading = {
  textAlign: 'center'
};

var NoDocs = function NoDocs() {
  return /*#__PURE__*/_react.default.createElement("div", {
    style: wrapper,
    className: "sb-nodocs sb-wrapper"
  }, /*#__PURE__*/_react.default.createElement("div", {
    style: main
  }, /*#__PURE__*/_react.default.createElement("h1", {
    style: heading
  }, "No Docs"), /*#__PURE__*/_react.default.createElement("p", null, "Sorry, but there are no docs for the selected story. To add them, set the story's\xA0", /*#__PURE__*/_react.default.createElement("code", null, "docs"), " parameter. If you think this is an error:"), /*#__PURE__*/_react.default.createElement("ul", null, /*#__PURE__*/_react.default.createElement("li", null, "Please check the story definition."), /*#__PURE__*/_react.default.createElement("li", null, "Please check the Storybook config."), /*#__PURE__*/_react.default.createElement("li", null, "Try reloading the page.")), /*#__PURE__*/_react.default.createElement("p", null, "If the problem persists, check the browser console, or the terminal you've run Storybook from.")));
};

exports.NoDocs = NoDocs;
NoDocs.displayName = "NoDocs";