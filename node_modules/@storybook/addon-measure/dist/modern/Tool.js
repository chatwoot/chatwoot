import React, { useCallback, useEffect } from 'react';
import { useGlobals, useStorybookApi } from '@storybook/api';
import { Icons, IconButton } from '@storybook/components';
import { TOOL_ID, ADDON_ID } from './constants';
export const Tool = () => {
  const [globals, updateGlobals] = useGlobals();
  const {
    measureEnabled
  } = globals;
  const api = useStorybookApi();
  const toggleMeasure = useCallback(() => updateGlobals({
    measureEnabled: !measureEnabled
  }), [updateGlobals, measureEnabled]);
  useEffect(() => {
    api.setAddonShortcut(ADDON_ID, {
      label: 'Toggle Measure [M]',
      defaultShortcut: ['M'],
      actionName: 'measure',
      showInMenu: false,
      action: toggleMeasure
    });
  }, [toggleMeasure, api]);
  return /*#__PURE__*/React.createElement(IconButton, {
    key: TOOL_ID,
    active: measureEnabled,
    title: "Enable measure",
    onClick: toggleMeasure
  }, /*#__PURE__*/React.createElement(Icons, {
    icon: "ruler"
  }));
};