import React, { useContext } from 'react';
import { Title as PureTitle } from '@storybook/components';
import { DocsContext } from './DocsContext';
const STORY_KIND_PATH_SEPARATOR = /\s*\/\s*/;
export const extractTitle = ({
  title
}) => {
  const groups = title.trim().split(STORY_KIND_PATH_SEPARATOR);
  return groups && groups[groups.length - 1] || title;
};
export const Title = ({
  children
}) => {
  const context = useContext(DocsContext);
  let text = children;

  if (!text) {
    text = extractTitle(context);
  }

  return text ? /*#__PURE__*/React.createElement(PureTitle, {
    className: "sbdocs-title"
  }, text) : null;
};