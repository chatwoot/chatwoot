import React from 'react';
import { Icons } from '@storybook/components';
export const ToolbarMenuListItem = ({
  left,
  right,
  title,
  value,
  icon,
  hideIcon,
  onClick,
  currentValue
}) => {
  const Icon = /*#__PURE__*/React.createElement(Icons, {
    style: {
      opacity: 1
    },
    icon: icon
  });
  const hasContent = left || right || title;
  const Item = {
    id: value,
    active: currentValue === value,
    onClick
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