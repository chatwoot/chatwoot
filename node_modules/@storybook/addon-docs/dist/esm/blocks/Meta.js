import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/web.url.js";
import "core-js/modules/web.url-search-params.js";
import React, { useContext } from 'react';
import global from 'global';
import { Anchor } from './Anchor';
import { DocsContext } from './DocsContext';
var document = global.document;

function getFirstStoryId(docsContext) {
  var stories = docsContext.componentStories();
  return stories.length > 0 ? stories[0].id : null;
}

function renderAnchor() {
  var context = useContext(DocsContext);
  var anchorId = getFirstStoryId(context) || context.id;
  return /*#__PURE__*/React.createElement(Anchor, {
    storyId: anchorId
  });
}
/**
 * This component is used to declare component metadata in docs
 * and gets transformed into a default export underneath the hood.
 */


export var Meta = function Meta() {
  var params = new URL(document.location).searchParams;
  var isDocs = params.get('viewMode') === 'docs';
  return isDocs ? renderAnchor() : null;
};