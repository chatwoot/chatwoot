const errorTypes = Object.freeze([
  'EvalError',
  'RangeError',
  'ReferenceError',
  'SyntaxError',
  'TypeError',
  'URIError'
]);

export function stringifyMessage({
  topic,
  channelId,
  message,
  messageId,
  keepalive
}) {
  const data = {
    channelId,
    topic,
    messageId,
    keepalive: !!keepalive,
    source: getSource()
  };

  if (message instanceof Error) {
    data.error = {
      name: message.name,
      message: message.message,
      stack: message.stack
    };
  } else {
    data.payload = message;
  }
  return JSON.stringify(data);
}

/**
 * Parse the received message for processing
 * @param  {string} dataString Message received
 * @return {object}            Object to be used for pub/sub
 */
export function parseMessage(dataString) {
  let data;
  try {
    data = JSON.parse(dataString);
  } catch (e) {
    return; // Wasn't meant for us.
  }
  if (!isRespondableMessage(data)) {
    return;
  }

  const { topic, channelId, messageId, keepalive } = data;
  const message =
    typeof data.error === 'object'
      ? buildErrorObject(data.error)
      : data.payload;

  return { topic, message, messageId, channelId, keepalive: !!keepalive };
}

/**
 * Verify the received message is from the "respondable" module
 * @private
 * @param  {Object} postedMessage The message received via postMessage
 * @return {Boolean}              `true` if the message is verified from respondable
 */
function isRespondableMessage(postedMessage) {
  return (
    typeof postedMessage === 'object' &&
    typeof postedMessage.channelId === 'string' &&
    postedMessage.source === getSource()
  );
}

/**
 * Convert a javascript Error into something that can be stringified
 * @param  {Error} error  Any type of error
 * @return {Object}       Processable object
 */
function buildErrorObject(error) {
  let msg = error.message || 'Unknown error occurred';
  const errorName = errorTypes.includes(error.name) ? error.name : 'Error';
  const ErrConstructor = window[errorName] || Error;

  if (error.stack) {
    msg += '\n' + error.stack.replace(error.message, '');
  }
  return new ErrConstructor(msg);
}

/**
 * get the unique string to be used to identify our instance of axe
 * @private
 */
function getSource() {
  let application = 'axeAPI';
  let version = '';

  // TODO: es-modules_audit
  if (typeof axe !== 'undefined' && axe._audit && axe._audit.application) {
    application = axe._audit.application;
  }
  if (typeof axe !== 'undefined') {
    // TODO: es-modules-version
    version = axe.version;
  }
  return application + '.' + version;
}
