import React from 'react';
import { Icons, IconButton } from '@storybook/components';
export const ToolbarMenuButton = ({
  active,
  title,
  icon,
  description,
  onClick
}) => {
  return /*#__PURE__*/React.createElement(IconButton, {
    active: active,
    title: description,
    onClick: onClick
  }, icon && /*#__PURE__*/React.createElement(Icons, {
    icon: icon
  }), title ? `\xa0${title}` : null);
};