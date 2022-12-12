import React from 'react';
import { addons, types } from '@storybook/addons';
import { ADDON_ID, TOOL_ID } from './constants';
import { Tool } from './Tool';
addons.register(ADDON_ID, function () {
  addons.add(TOOL_ID, {
    type: types.TOOL,
    title: 'Measure',
    match: function match(_ref) {
      var viewMode = _ref.viewMode;
      return viewMode === 'story';
    },
    render: function render() {
      return /*#__PURE__*/React.createElement(Tool, null);
    }
  });
});