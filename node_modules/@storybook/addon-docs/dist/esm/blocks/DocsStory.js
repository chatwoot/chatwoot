import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

import "core-js/modules/es.function.name.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import React from 'react';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { Subheading } from './Subheading';
import { Anchor } from './Anchor';
import { Description } from './Description';
import { Story } from './Story';
import { Canvas } from './Canvas';
var warnStoryDescription = deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Deprecated parameter: docs.storyDescription => docs.description.story\n      \n    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#docs-description-parameter\n  "]))));
export var DocsStory = function DocsStory(_ref) {
  var id = _ref.id,
      name = _ref.name,
      _ref$expanded = _ref.expanded,
      expanded = _ref$expanded === void 0 ? true : _ref$expanded,
      _ref$withToolbar = _ref.withToolbar,
      withToolbar = _ref$withToolbar === void 0 ? false : _ref$withToolbar,
      _ref$parameters = _ref.parameters,
      parameters = _ref$parameters === void 0 ? {} : _ref$parameters;
  var description;
  var docs = parameters.docs;

  if (expanded && docs) {
    var _docs$description;

    description = (_docs$description = docs.description) === null || _docs$description === void 0 ? void 0 : _docs$description.story;

    if (!description) {
      description = docs.storyDescription;
      if (description) warnStoryDescription();
    }
  }

  var subheading = expanded && name;
  return /*#__PURE__*/React.createElement(Anchor, {
    storyId: id
  }, subheading && /*#__PURE__*/React.createElement(Subheading, null, subheading), description && /*#__PURE__*/React.createElement(Description, {
    markdown: description
  }), /*#__PURE__*/React.createElement(Canvas, {
    withToolbar: withToolbar
  }, /*#__PURE__*/React.createElement(Story, {
    id: id,
    parameters: parameters
  })));
};