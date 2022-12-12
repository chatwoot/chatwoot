function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import React from 'react';
import { useGlobalTypes } from '@storybook/api';
import { Separator } from '@storybook/components';
import { ToolbarMenuList } from './ToolbarMenuList';
import { normalizeArgType } from '../utils/normalize-toolbar-arg-type';

/**
 * A smart component for handling manager-preview interactions.
 */
export const ToolbarManager = () => {
  const globalTypes = useGlobalTypes();
  const globalIds = Object.keys(globalTypes).filter(id => !!globalTypes[id].toolbar);

  if (!globalIds.length) {
    return null;
  }

  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Separator, null), globalIds.map(id => {
    const normalizedArgType = normalizeArgType(id, globalTypes[id]);
    return /*#__PURE__*/React.createElement(ToolbarMenuList, _extends({
      key: id,
      id: id
    }, normalizedArgType));
  }));
};