import React from 'react';
import { addons, types } from '@storybook/addons';
import { AddonPanel } from '@storybook/components';
import { useArgTypes } from '@storybook/api';
import { ControlsPanel } from './ControlsPanel';
import { ADDON_ID, PARAM_KEY } from './constants';
addons.register(ADDON_ID, api => {
  addons.addPanel(ADDON_ID, {
    title() {
      const rows = useArgTypes();
      const controlsCount = Object.values(rows).filter(argType => argType === null || argType === void 0 ? void 0 : argType.control).length;
      const suffix = controlsCount === 0 ? '' : ` (${controlsCount})`;
      return `Controls${suffix}`;
    },

    type: types.PANEL,
    paramKey: PARAM_KEY,
    render: ({
      key,
      active
    }) => {
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