import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.object.assign.js";
var _excluded = ["theme"];
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.function.name.js";

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import React, { Fragment } from 'react';
import { styled, withTheme } from '@storybook/theming';
import Inspector from 'react-inspector';
import { ActionBar, ScrollArea } from '@storybook/components';
import { Action, InspectorContainer, Counter } from './style';
export var Wrapper = styled(function (_ref) {
  var children = _ref.children,
      className = _ref.className;
  return /*#__PURE__*/React.createElement(ScrollArea, {
    horizontal: true,
    vertical: true,
    className: className
  }, children);
})({
  margin: 0,
  padding: '10px 5px 20px'
});
var ThemedInspector = withTheme(function (_ref2) {
  var theme = _ref2.theme,
      props = _objectWithoutProperties(_ref2, _excluded);

  return /*#__PURE__*/React.createElement(Inspector, _extends({
    theme: theme.addonActionsTheme || 'chromeLight'
  }, props));
});
export var ActionLogger = function ActionLogger(_ref3) {
  var actions = _ref3.actions,
      onClear = _ref3.onClear;
  return /*#__PURE__*/React.createElement(Fragment, null, /*#__PURE__*/React.createElement(Wrapper, {
    title: "actionslogger"
  }, actions.map(function (action) {
    return /*#__PURE__*/React.createElement(Action, {
      key: action.id
    }, action.count > 1 && /*#__PURE__*/React.createElement(Counter, null, action.count), /*#__PURE__*/React.createElement(InspectorContainer, null, /*#__PURE__*/React.createElement(ThemedInspector, {
      sortObjectKeys: true,
      showNonenumerable: false,
      name: action.data.name,
      data: action.data.args || action.data
    })));
  })), /*#__PURE__*/React.createElement(ActionBar, {
    actionItems: [{
      title: 'Clear',
      onClick: onClear
    }]
  }));
};