import React from 'react';
import { Icons } from '@storybook/components';
export var ToolbarMenuListItem = function ToolbarMenuListItem(_ref) {
  var left = _ref.left,
      right = _ref.right,
      title = _ref.title,
      value = _ref.value,
      icon = _ref.icon,
      hideIcon = _ref.hideIcon,
      onClick = _ref.onClick,
      currentValue = _ref.currentValue;
  var Icon = /*#__PURE__*/React.createElement(Icons, {
    style: {
      opacity: 1
    },
    icon: icon
  });
  var hasContent = left || right || title;
  var Item = {
    id: value,
    active: currentValue === value,
    onClick: onClick
  };

  if (left) {
    Item.left = left;
  }

  if (right) {
    Item.right = right;
  }

  if (title) {
    Item.title = title;
  }

  if (icon && !hideIcon) {
    if (hasContent && !right) {
      Item.right = Icon;
    } else if (hasContent && !left) {
      Item.left = Icon;
    } else if (!hasContent) {
      Item.right = Icon;
    }
  }

  return Item;
};