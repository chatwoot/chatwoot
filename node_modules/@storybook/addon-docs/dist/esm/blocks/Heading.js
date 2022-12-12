import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import React from 'react';
import { H2 } from '@storybook/components';
import { HeaderMdx } from './mdx';
export var Heading = function Heading(_ref) {
  var children = _ref.children,
      disableAnchor = _ref.disableAnchor;

  if (disableAnchor || typeof children !== 'string') {
    return /*#__PURE__*/React.createElement(H2, null, children);
  }

  var tagID = children.toLowerCase().replace(/[^a-z0-9]/gi, '-');
  return /*#__PURE__*/React.createElement(HeaderMdx, {
    as: "h2",
    id: tagID
  }, children);
};