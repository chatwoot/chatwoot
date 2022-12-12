import React from 'react';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { Subheading } from './Subheading';
import { Anchor } from './Anchor';
import { Description } from './Description';
import { Story } from './Story';
import { Canvas } from './Canvas';
const warnStoryDescription = deprecate(() => {}, dedent`
    Deprecated parameter: docs.storyDescription => docs.description.story
      
    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#docs-description-parameter
  `);
export const DocsStory = ({
  id,
  name,
  expanded = true,
  withToolbar = false,
  parameters = {}
}) => {
  let description;
  const {
    docs
  } = parameters;

  if (expanded && docs) {
    var _docs$description;

    description = (_docs$description = docs.description) === null || _docs$description === void 0 ? void 0 : _docs$description.story;

    if (!description) {
      description = docs.storyDescription;
      if (description) warnStoryDescription();
    }
  }

  const subheading = expanded && name;
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