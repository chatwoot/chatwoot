/**
 * @file log.js
 * @since 2.0.0
 */

import videojs from 'video.js';

const ERROR = 'error';
const WARN = 'warn';

/**
 * Log message (if the debug option is enabled).
 *
 * @private
 * @param {Array} args - The arguments to be passed to the matching console
 *     method.
 * @param {string} logType - The name of the console method to use.
 * @param {boolean} debug - Whether or not the debug option is enabled or not.
 */
const log = function(args, logType, debug)
{
    if (debug === true) {
        if (logType === ERROR) {
            videojs.log.error(args);
        } else if (logType === WARN) {
            videojs.log.warn(args);
        } else {
            videojs.log(args);
        }
    }
};

export default log;
