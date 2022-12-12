import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import React from 'react';
import { Icons, IconButton } from '@storybook/components';
export var ToolbarMenuButton = function ToolbarMenuButton(_ref) {
  var active = _ref.active,
      title = _ref.title,
      icon = _ref.icon,
      description = _ref.description,
      onClick = _ref.onClick;
  return /*#__PURE__*/React.createElement(IconButton, {
    active: active,
    title: description,
    onClick: onClick
  }, icon && /*#__PURE__*/React.createElement(Icons, {
    icon: icon
  }), title ? "\xA0".concat(title) : null);
};