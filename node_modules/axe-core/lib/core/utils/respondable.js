import { v4 as createUuid } from './uuid';
import assert from './assert';
import { setDefaultFrameMessenger } from './frame-messenger';

let closeHandler;
let postMessage;

const topicHandlers = {};

/**
 * Post a message to a window who may or may not respond to it.
 * @param  {Window}   win      The window to post the message to
 * @param  {String}   topic    The topic of the message
 * @param  {Object}   message  The message content
 * @param  {Boolean}  keepalive Whether to allow multiple responses - default is false
 * @param  {Function} replyHandler The function to invoke when/if the message is responded to
 */
export default function respondable(
  win,
  topic,
  message,
  keepalive,
  replyHandler
) {
  const data = {
    topic,
    message,
    channelId: `${createUuid()}:${createUuid()}`,
    keepalive
  };

  return postMessage(win, data, replyHandler);
}

/**
 * Handle incoming window messages
 * @param  {Object} data
 * @param {Function} responder
 */
function messageListener(data, responder) {
  const { topic, message, keepalive } = data;
  const topicHandler = topicHandlers[topic];
  if (!topicHandler) {
    return;
  }

  try {
    topicHandler(message, keepalive, responder);
  } catch (error) {
    axe.log(error);
    responder(error, keepalive);
  }
}

/**
 * Update how respondable communicates with iframes.
 * @param {Function} frameHandler  Object with open, post, and close functions
 */
respondable.updateMessenger = function updateMessenger({ open, post }) {
  assert(typeof open === 'function', 'open callback must be a function');
  assert(typeof post === 'function', 'post callback must be a function');

  if (closeHandler) {
    closeHandler();
  }

  var close = open(messageListener);

  if (close) {
    assert(
      typeof close === 'function',
      'open callback must return a cleanup function'
    );
    closeHandler = close;
  } else {
    closeHandler = null;
  }

  postMessage = post;
};

/**
 * Subscribe to messages sent via the `respondable` module.
 *
 * Axe._load uses this to listen for messages from other frames
 *
 * @param  {String}   topic    The topic to listen to
 * @param  {Function} topicHandler The function to invoke when a message is received
 */
respondable.subscribe = function subscribe(topic, topicHandler) {
  assert(
    typeof topicHandler === 'function',
    'Subscriber callback must be a function'
  );
  assert(!topicHandlers[topic], `Topic ${topic} is already registered to.`);

  topicHandlers[topic] = topicHandler;
};

/**
 * checks if the current context is inside a frame
 * @return {Boolean}
 */
respondable.isInFrame = function isInFrame(win = window) {
  return !!win.frameElement;
};

setDefaultFrameMessenger(respondable);
