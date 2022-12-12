"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createContext = void 0;

var _react = require("react");

var createContext = function createContext(_ref) {
  var api = _ref.api,
      state = _ref.state;
  return /*#__PURE__*/(0, _react.createContext)({
    api: api,
    state: state
  });
};

exports.createContext = createContext;