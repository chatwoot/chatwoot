import React from 'react';
import { H3 } from '@storybook/components';
import { HeaderMdx } from './mdx';
export const Subheading = ({
  children,
  disableAnchor
}) => {
  if (disableAnchor || typeof children !== 'string') {
    return /*#__PURE__*/React.createElement(H3, null, children);
  }

  const tagID = children.toLowerCase().replace(/[^a-z0-9]/gi, '-');
  return /*#__PURE__*/React.createElement(HeaderMdx, {
    as: "h3",
    id: tagID
  }, children);
};