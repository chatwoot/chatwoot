"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Wrapper = void 0;

var _react = _interopRequireDefault(require("react"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Wrapper = function Wrapper(_ref) {
  var children = _ref.children;
  return /*#__PURE__*/_react.default.createElement("div", {
    style: {
      fontFamily: 'sans-serif'
    }
  }, children);
};

exports.Wrapper = Wrapper;