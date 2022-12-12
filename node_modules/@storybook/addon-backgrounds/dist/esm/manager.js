import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.match.js";
import React, { Fragment } from 'react';
import { addons, types } from '@storybook/addons';
import { ADDON_ID } from './constants';
import { BackgroundSelector } from './containers/BackgroundSelector';
import { GridSelector } from './containers/GridSelector';
addons.register(ADDON_ID, function () {
  addons.add(ADDON_ID, {
    title: 'Backgrounds',
    type: types.TOOL,
    match: function match(_ref) {
      var viewMode = _ref.viewMode;
      return !!(viewMode && viewMode.match(/^(story|docs)$/));
    },
    render: function render() {
      return /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(BackgroundSelector, null), /*#__PURE__*/React.createElement(GridSelector, null));
    }
  });
});