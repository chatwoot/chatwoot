function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.object.assign.js";
import React, { useContext } from 'react';
import { DocsContext } from './DocsContext';
import { DocsStory } from './DocsStory';
import { Heading } from './Heading';
export var Stories = function Stories(_ref) {
  var title = _ref.title,
      _ref$includePrimary = _ref.includePrimary,
      includePrimary = _ref$includePrimary === void 0 ? false : _ref$includePrimary;

  var _useContext = useContext(DocsContext),
      componentStories = _useContext.componentStories;

  var stories = componentStories();
  stories = stories.filter(function (story) {
    var _story$parameters, _story$parameters$doc;

    return !((_story$parameters = story.parameters) !== null && _story$parameters !== void 0 && (_story$parameters$doc = _story$parameters.docs) !== null && _story$parameters$doc !== void 0 && _story$parameters$doc.disable);
  });
  if (!includePrimary) stories = stories.slice(1);

  if (!stories || stories.length === 0) {
    return null;
  }

  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Heading, null, title), stories.map(function (story) {
    return story && /*#__PURE__*/React.createElement(DocsStory, _extends({
      key: story.id
    }, story, {
      expanded: true
    }));
  }));
};
Stories.defaultProps = {
  title: 'Stories'
};