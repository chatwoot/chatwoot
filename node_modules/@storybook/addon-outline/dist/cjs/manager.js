"use strict";

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.match.js");

var _react = _interopRequireDefault(require("react"));

var _addons = require("@storybook/addons");

var _constants = require("./constants");

var _OutlineSelector = require("./OutlineSelector");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_addons.addons.register(_constants.ADDON_ID, function () {
  _addons.addons.add(_constants.ADDON_ID, {
    title: 'Outline',
    type: _addons.types.TOOL,
    match: function match(_ref) {
      var viewMode = _ref.viewMode;
      return !!(viewMode && viewMode.match(/^(story|docs)$/));
    },
    render: function render() {
      return /*#__PURE__*/_react.default.createElement(_OutlineSelector.OutlineSelector, null);
    }
  });
});