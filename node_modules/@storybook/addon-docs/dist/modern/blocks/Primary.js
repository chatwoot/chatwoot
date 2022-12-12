function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import React, { useContext } from 'react';
import { DocsContext } from './DocsContext';
import { DocsStory } from './DocsStory';
export const Primary = ({
  name
}) => {
  const {
    componentStories: getComponentStories
  } = useContext(DocsContext);
  const componentStories = getComponentStories();
  let story;

  if (componentStories) {
    story = name ? componentStories.find(s => s.name === name) : componentStories[0];
  }

  return story ? /*#__PURE__*/React.createElement(DocsStory, _extends({}, story, {
    expanded: false,
    withToolbar: true
  })) : null;
};