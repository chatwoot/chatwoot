"use strict";

var _react = _interopRequireDefault(require("react"));

var _addons = require("@storybook/addons");

var _constants = require("./constants");

var _Tool = require("./Tool");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_addons.addons.register(_constants.ADDON_ID, function () {
  _addons.addons.add(_constants.TOOL_ID, {
    type: _addons.types.TOOL,
    title: 'Measure',
    match: function match(_ref) {
      var viewMode = _ref.viewMode;
      return viewMode === 'story';
    },
    render: function render() {
      return /*#__PURE__*/_react.default.createElement(_Tool.Tool, null);
    }
  });
});