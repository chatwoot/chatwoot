import React from 'react';
import ReactDOM from 'react-dom';
import { NoDocs } from './NoDocs';
export function renderDocs(story, docsContext, element, callback) {
  return renderDocsAsync(story, docsContext, element).then(callback);
}

async function renderDocsAsync(story, docsContext, element) {
  var _docs$getContainer, _docs$getPage;

  const {
    docs
  } = story.parameters;

  if ((docs !== null && docs !== void 0 && docs.getPage || docs !== null && docs !== void 0 && docs.page) && !(docs !== null && docs !== void 0 && docs.getContainer || docs !== null && docs !== void 0 && docs.container)) {
    throw new Error('No `docs.container` set, did you run `addon-docs/preset`?');
  }

  const DocsContainer = docs.container || (await ((_docs$getContainer = docs.getContainer) === null || _docs$getContainer === void 0 ? void 0 : _docs$getContainer.call(docs))) || (({
    children
  }) => /*#__PURE__*/React.createElement(React.Fragment, null, children));

  const Page = docs.page || (await ((_docs$getPage = docs.getPage) === null || _docs$getPage === void 0 ? void 0 : _docs$getPage.call(docs))) || NoDocs; // Use `componentId` as a key so that we force a re-render every time
  // we switch components

  const docsElement = /*#__PURE__*/React.createElement(DocsContainer, {
    key: story.componentId,
    context: docsContext
  }, /*#__PURE__*/React.createElement(Page, null));
  await new Promise(resolve => {
    ReactDOM.render(docsElement, element, resolve);
  });
}

export function unmountDocs(element) {
  ReactDOM.unmountComponentAtNode(element);
}