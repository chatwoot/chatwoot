import React from 'react';
import { H2 } from '@storybook/components';
import { HeaderMdx } from './mdx';
export const Heading = ({
  children,
  disableAnchor
}) => {
  if (disableAnchor || typeof children !== 'string') {
    return /*#__PURE__*/React.createElement(H2, null, children);
  }

  const tagID = children.toLowerCase().replace(/[^a-z0-9]/gi, '-');
  return /*#__PURE__*/React.createElement(HeaderMdx, {
    as: "h2",
    id: tagID
  }, children);
};