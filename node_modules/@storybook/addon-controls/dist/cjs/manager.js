"use strict";

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.values.js");

var _react = _interopRequireDefault(require("react"));

var _addons = require("@storybook/addons");

var _components = require("@storybook/components");

var _api = require("@storybook/api");

var _ControlsPanel = require("./ControlsPanel");

var _constants = require("./constants");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

_addons.addons.register(_constants.ADDON_ID, function (api) {
  _addons.addons.addPanel(_constants.ADDON_ID, {
    title: function title() {
      var rows = (0, _api.useArgTypes)();
      var controlsCount = Object.values(rows).filter(function (argType) {
        return argType === null || argType === void 0 ? void 0 : argType.control;
      }).length;
      var suffix = controlsCount === 0 ? '' : " (".concat(controlsCount, ")");
      return "Controls".concat(suffix);
    },
    type: _addons.types.PANEL,
    paramKey: _constants.PARAM_KEY,
    render: function render(_ref) {
      var key = _ref.key,
          active = _ref.active;

      if (!active || !api.getCurrentStoryData()) {
        return null;
      }

      return /*#__PURE__*/_react.default.createElement(_components.AddonPanel, {
        key: key,
        active: active
      }, /*#__PURE__*/_react.default.createElement(_ControlsPanel.ControlsPanel, null));
    }
  });
});