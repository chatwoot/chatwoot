/* eslint-disable no-underscore-dangle */
/* global window */

export const setCompodocJson = (compodocJson) => {
  // @ts-ignore
  window.__STORYBOOK_COMPODOC_JSON__ = compodocJson;
};
