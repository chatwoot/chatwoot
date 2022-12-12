import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.values.js";
import React from 'react';
import { addons, types } from '@storybook/addons';
import { AddonPanel } from '@storybook/components';
import { useArgTypes } from '@storybook/api';
import { ControlsPanel } from './ControlsPanel';
import { ADDON_ID, PARAM_KEY } from './constants';
addons.register(ADDON_ID, function (api) {
  addons.addPanel(ADDON_ID, {
    title: function title() {
      var rows = useArgTypes();
      var controlsCount = Object.values(rows).filter(function (argType) {
        return argType === null || argType === void 0 ? void 0 : argType.control;
      }).length;
      var suffix = controlsCount === 0 ? '' : " (".concat(controlsCount, ")");
      return "Controls".concat(suffix);
    },
    type: types.PANEL,
    paramKey: PARAM_KEY,
    render: function render(_ref) {
      var key = _ref.key,
          active = _ref.active;

      if (!active || !api.getCurrentStoryData()) {
        return null;
      }

      return /*#__PURE__*/React.createElement(AddonPanel, {
        key: key,
        active: active
      }, /*#__PURE__*/React.createElement(ControlsPanel, null));
    }
  });
});