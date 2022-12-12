import React, { useContext } from 'react';
import { Subtitle as PureSubtitle } from '@storybook/components';
import { DocsContext } from './DocsContext';
export const Subtitle = ({
  children
}) => {
  const {
    id,
    storyById
  } = useContext(DocsContext);
  const {
    parameters
  } = storyById(id);
  let text = children;

  if (!text) {
    text = parameters === null || parameters === void 0 ? void 0 : parameters.componentSubtitle;
  }

  return text ? /*#__PURE__*/React.createElement(PureSubtitle, {
    className: "sbdocs-subtitle"
  }, text) : null;
};