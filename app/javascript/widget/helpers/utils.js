import { WOOT_PREFIX } from './constants';

export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const sendMessage = msg => {
  window.parent.postMessage(
    `chatwoot-widget:${JSON.stringify({ ...msg })}`,
    '*'
  );
};

export const IFrameHelper = {
  isIFrame: () => window.self !== window.top,
  sendMessage,
  isAValidEvent: e => {
    const isDataAString = typeof e.data === 'string';
    return isDataAString && e.data.indexOf(WOOT_PREFIX) === 0;
  },
  getMessage: e => JSON.parse(e.data.replace(WOOT_PREFIX, '')),
};
export const RNHelper = {
  isRNWebView: () => window.ReactNativeWebView,
  sendMessage: msg => {
    window.ReactNativeWebView.postMessage(
      `chatwoot-widget:${JSON.stringify({ ...msg })}`
    );
  },
};

export const groupBy = (array, predicate) => {
  return array.reduce((acc, value) => {
    (acc[predicate(value)] ||= []).push(value);
    return acc;
  }, {});
};
