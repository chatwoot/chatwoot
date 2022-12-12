function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.object.assign.js";
import React, { useContext } from 'react';
import { DocsContext } from './DocsContext';
import { DocsStory } from './DocsStory';
export var Primary = function Primary(_ref) {
  var name = _ref.name;

  var _useContext = useContext(DocsContext),
      getComponentStories = _useContext.componentStories;

  var componentStories = getComponentStories();
  var story;

  if (componentStories) {
    story = name ? componentStories.find(function (s) {
      return s.name === name;
    }) : componentStories[0];
  }

  return story ? /*#__PURE__*/React.createElement(DocsStory, _extends({}, story, {
    expanded: false,
    withToolbar: true
  })) : null;
};