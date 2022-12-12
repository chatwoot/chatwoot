"use strict";

var _react = _interopRequireDefault(require("react"));

var _addons = require("@storybook/addons");

var _ToolbarManager = require("./components/ToolbarManager");

var _constants = require("./constants");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_addons.addons.register(_constants.ADDON_ID, function () {
  return _addons.addons.add(_constants.ADDON_ID, {
    title: _constants.ADDON_ID,
    type: _addons.types.TOOL,
    match: function match() {
      return true;
    },
    render: function render() {
      return /*#__PURE__*/_react.default.createElement(_ToolbarManager.ToolbarManager, null);
    }
  });
});