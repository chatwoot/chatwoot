import "core-js/modules/es.array.reduce.js";
import React from 'react';
import { useArgs, useGlobals, useArgTypes, useParameter, useStorybookState } from '@storybook/api';
import { ArgsTable, NoControlsWarning } from '@storybook/components';
import { PARAM_KEY } from './constants';
export const ControlsPanel = () => {
  const [args, updateArgs, resetArgs] = useArgs();
  const [globals] = useGlobals();
  const rows = useArgTypes();
  const isArgsStory = useParameter('__isArgsStory', false);
  const {
    expanded,
    sort,
    presetColors,
    hideNoControlsWarning = false
  } = useParameter(PARAM_KEY, {});
  const {
    path
  } = useStorybookState();
  const hasControls = Object.values(rows).some(arg => arg === null || arg === void 0 ? void 0 : arg.control);
  const showWarning = !(hasControls && isArgsStory) && !hideNoControlsWarning;
  const withPresetColors = Object.entries(rows).reduce((acc, [key, arg]) => {
    var _arg$control, _arg$control2;

    if ((arg === null || arg === void 0 ? void 0 : (_arg$control = arg.control) === null || _arg$control === void 0 ? void 0 : _arg$control.type) !== 'color' || arg !== null && arg !== void 0 && (_arg$control2 = arg.control) !== null && _arg$control2 !== void 0 && _arg$control2.presetColors) acc[key] = arg;else acc[key] = Object.assign({}, arg, {
      control: Object.assign({}, arg.control, {
        presetColors
      })
    });
    return acc;
  }, {});
  return /*#__PURE__*/React.createElement(React.Fragment, null, showWarning && /*#__PURE__*/React.createElement(NoControlsWarning, null), /*#__PURE__*/React.createElement(ArgsTable, {
    key: path,
    // resets state when switching stories
    compact: !expanded && hasControls,
    rows: withPresetColors,
    args,
    globals,
    updateArgs,
    resetArgs,
    inAddonPanel: true,
    sort
  }));
};