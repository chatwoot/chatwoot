/*eslint no-console: 0 */

/**
 * Logs a message to the developer console (if it exists and is active).
 */
function log() {
  if (typeof console === 'object' && console.log) {
    // IE does not support console.log.apply
    Function.prototype.apply.call(console.log, console, arguments);
  }
}

export default log;
