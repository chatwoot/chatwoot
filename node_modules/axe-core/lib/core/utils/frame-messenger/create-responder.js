import { postMessage } from './post-message';

/**
 * Helper closure to create a function that may be used to respond to a message
 * @private
 * @param  {Window} win    The window from which the message originated
 * @param  {String} channelId   The "unique" ID of the original message
 * @return {Function}      A function that may be invoked to respond to the message
 */
export function createResponder(win, channelId, sendToParent = true) {
  return function respond(message, keepalive, replyHandler) {
    const data = { channelId, message, keepalive };
    postMessage(win, data, sendToParent, replyHandler);
  };
}
