const _excluded = ["theme"];

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import React, { Fragment } from 'react';
import { styled, withTheme } from '@storybook/theming';
import Inspector from 'react-inspector';
import { ActionBar, ScrollArea } from '@storybook/components';
import { Action, InspectorContainer, Counter } from './style';
export const Wrapper = styled(({
  children,
  className
}) => /*#__PURE__*/React.createElement(ScrollArea, {
  horizontal: true,
  vertical: true,
  className: className
}, children))({
  margin: 0,
  padding: '10px 5px 20px'
});
const ThemedInspector = withTheme(_ref => {
  let {
    theme
  } = _ref,
      props = _objectWithoutPropertiesLoose(_ref, _excluded);

  return /*#__PURE__*/React.createElement(Inspector, _extends({
    theme: theme.addonActionsTheme || 'chromeLight'
  }, props));
});
export const ActionLogger = ({
  actions,
  onClear
}) => /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(Wrapper, {
  title: "actionslogger"
}, actions.map(action => /*#__PURE__*/React.createElement(Action, {
  key: action.id
}, action.count > 1 && /*#__PURE__*/React.createElement(Counter, null, action.count), /*#__PURE__*/React.createElement(InspectorContainer, null, /*#__PURE__*/React.createElement(ThemedInspector, {
  sortObjectKeys: true,
  showNonenumerable: false,
  name: action.data.name,
  data: action.data.args || action.data
}))))), /*#__PURE__*/React.createElement(ActionBar, {
  actionItems: [{
    title: 'Clear',
    onClick: onClear
  }]
}));