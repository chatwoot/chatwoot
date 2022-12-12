import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.match.js";
import React from 'react';
import { addons, types } from '@storybook/addons';
import { ADDON_ID } from './constants';
import { OutlineSelector } from './OutlineSelector';
addons.register(ADDON_ID, function () {
  addons.add(ADDON_ID, {
    title: 'Outline',
    type: types.TOOL,
    match: function match(_ref) {
      var viewMode = _ref.viewMode;
      return !!(viewMode && viewMode.match(/^(story|docs)$/));
    },
    render: function render() {
      return /*#__PURE__*/React.createElement(OutlineSelector, null);
    }
  });
});