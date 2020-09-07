import { WOOT_PREFIX } from './constants';

export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const arrayToHashById = array =>
  array.reduce((map, obj) => {
    const newMap = map;
    newMap[obj.id] = obj;
    return newMap;
  }, {});

export const IFrameHelper = {
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
