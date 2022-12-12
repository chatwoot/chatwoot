import React from 'react';
import { addons, types } from '@storybook/addons';
import { ToolbarManager } from './components/ToolbarManager';
import { ADDON_ID } from './constants';
addons.register(ADDON_ID, function () {
  return addons.add(ADDON_ID, {
    title: ADDON_ID,
    type: types.TOOL,
    match: function match() {
      return true;
    },
    render: function render() {
      return /*#__PURE__*/React.createElement(ToolbarManager, null);
    }
  });
});