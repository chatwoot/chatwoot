/**
 * If the first argument is falsy, throw an error using the second argument as a message.
 * @param {boolean} bool
 * @param {string} message
 */
function assert(bool, message) {
  if (!bool) {
    throw new Error(message);
  }
}

export default assert;
