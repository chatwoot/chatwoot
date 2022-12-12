import React, { useContext } from 'react';
import global from 'global';
import { Anchor } from './Anchor';
import { DocsContext } from './DocsContext';
const {
  document
} = global;

function getFirstStoryId(docsContext) {
  const stories = docsContext.componentStories();
  return stories.length > 0 ? stories[0].id : null;
}

function renderAnchor() {
  const context = useContext(DocsContext);
  const anchorId = getFirstStoryId(context) || context.id;
  return /*#__PURE__*/React.createElement(Anchor, {
    storyId: anchorId
  });
}
/**
 * This component is used to declare component metadata in docs
 * and gets transformed into a default export underneath the hood.
 */


export const Meta = () => {
  const params = new URL(document.location).searchParams;
  const isDocs = params.get('viewMode') === 'docs';
  return isDocs ? renderAnchor() : null;
};