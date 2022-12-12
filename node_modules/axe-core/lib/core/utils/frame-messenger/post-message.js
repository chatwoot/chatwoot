import { stringifyMessage } from './message-parser';
import { assertIsParentWindow, assertIsFrameWindow } from './assert-window';
import { storeReplyHandler } from './channel-store';
import { createMessageId } from './message-id';

/**
 * Posts the message to correct frame.
 * This abstraction necessary because IE9 & 10 do not support posting Objects; only strings
 * @private
 * @param  {Window}   win         The `window` to post the message to
 * @param  {Object}   data        Payload with topic, message, channelId & keepalive
 * @param  {Boolean}  sendToParent Whether the message goes to the parent or the child frame
 * @param  {Function} replyNandler Function to call with the response
 *
 * @return {Boolean} true if the message was sent
 */
export function postMessage(win, data, sendToParent, replyHandler) {
  if (typeof replyHandler === 'function') {
    storeReplyHandler(data.channelId, replyHandler, sendToParent);
  }

  // Prevent messaging to an inappropriate window
  sendToParent ? assertIsParentWindow(win) : assertIsFrameWindow(win);
  if (data.message instanceof Error && !sendToParent) {
    axe.log(data.message);
    return false;
  }

  const dataString = stringifyMessage({
    messageId: createMessageId(),
    ...data
  });

  // TODO: es_modules_audit
  const { allowedOrigins } = axe._audit;
  if (!allowedOrigins || !allowedOrigins.length) {
    return false;
  }

  // There is no way to know the origin of `win`, so we'll try them all.
  allowedOrigins.forEach(origin => {
    try {
      win.postMessage(dataString, origin);
    } catch (err) {
      if (err instanceof win.DOMException) {
        throw new Error(
          `allowedOrigins value "${origin}" is not a valid origin`
        );
      }
      throw err;
    }
  });
  return true;
}
