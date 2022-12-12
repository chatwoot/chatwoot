import { postMessage } from './frame-messenger/post-message';
import { messageHandler } from './frame-messenger/message-handler';

/**
 * Setup default axe frame messenger (make a function so we can
 * call it during tests to reset respondable to default state).
 * @param {Object} respondable
 */
export const frameMessenger = {
  open(topicHandler) {
    if (typeof window.addEventListener !== 'function') {
      return;
    }

    const handler = function(messageEvent) {
      messageHandler(messageEvent, topicHandler);
    };
    window.addEventListener('message', handler, false);

    return () => {
      window.removeEventListener('message', handler, false);
    };
  },

  post(win, data, replyHandler) {
    if (typeof window.addEventListener !== 'function') {
      return false;
    }
    return postMessage(win, data, false, replyHandler);
  }
};

/**
 * Setup default axe frame messenger (make a function so we can
 * call it during tests to reset respondable to default state).
 * @param {Object} respondable
 */
export function setDefaultFrameMessenger(respondable) {
  respondable.updateMessenger(frameMessenger);
}
