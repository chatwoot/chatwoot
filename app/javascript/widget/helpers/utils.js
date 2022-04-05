import { WOOT_PREFIX } from './constants';

export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const arrayToHashById = array =>
  array.reduce((map, obj) => {
    const newMap = map;
    newMap[obj.id] = obj;
    return newMap;
  }, {});

// Ux.App adding more config that can be set from outside the iframe
export const defaultIframeConfig = {
  showUnreadBubbles: false,
  startConversationAlwaysRightFromStart: true,
};

export const IFrameHelper = {
  IFrameConfig: () => defaultIframeConfig, // implement something with iframe postMessage, and such, if needed
  isIFrame: () => window.self !== window.top,
  sendMessage: msg => {
    window.parent.postMessage(
      `chatwoot-widget:${JSON.stringify({ ...msg })}`,
      '*'
    );
  },
  isAValidEvent: e => {
    const isDataAString = typeof e.data === 'string';
    const isAValidWootEvent =
      isDataAString && e.data.indexOf(WOOT_PREFIX) === 0;
    return isAValidWootEvent;
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
