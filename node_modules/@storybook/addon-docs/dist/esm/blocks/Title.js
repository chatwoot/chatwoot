import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.string.trim.js";
import React, { useContext } from 'react';
import { Title as PureTitle } from '@storybook/components';
import { DocsContext } from './DocsContext';
var STORY_KIND_PATH_SEPARATOR = /\s*\/\s*/;
export var extractTitle = function extractTitle(_ref) {
  var title = _ref.title;
  var groups = title.trim().split(STORY_KIND_PATH_SEPARATOR);
  return groups && groups[groups.length - 1] || title;
};
export var Title = function Title(_ref2) {
  var children = _ref2.children;
  var context = useContext(DocsContext);
  var text = children;

  if (!text) {
    text = extractTitle(context);
  }

  return text ? /*#__PURE__*/React.createElement(PureTitle, {
    className: "sbdocs-title"
  }, text) : null;
};