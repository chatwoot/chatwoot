/**
 * @file format-time.js
 * @since 2.0.0
 */

import addZero from 'add-zero';
import parseMilliseconds from 'parse-ms';

/**
 * Format seconds as a duration string.
 *
 * Either formatted as:
 *
 * - DD:HH:MM:SS (> 24 hours)
 * - HH:MM:SS (> 1 hour)
 * - MM:SS:MSS (`displayMilliseconds = true`)
 * - MM:SS (`displayMilliseconds = false`)
 *
 * Supplying a guide (in seconds) will force a number of leading zeros
 * to cover the length of the guide.
 *
 * @param {number} seconds - Number of seconds to be turned into a
 *     string.
 * @param {number} guide - Number (in seconds) to model the string after.
 * @param {boolean} displayMilliseconds - Display milliseconds or not.
 * @return {string} Formatted duration time, e.g '00:12:653'.
 * @private
 */
const formatTime = function(seconds, guide, displayMilliseconds = true) {
    seconds = seconds < 0 ? 0 : seconds;
    if (isNaN(seconds) || seconds === Infinity) {
        seconds = 0;
    }
    const inputTime = parseMilliseconds(seconds * 1000);
    let guideTime = inputTime;
    if (guide !== undefined) {
        guideTime = parseMilliseconds(guide * 1000);
    }
    const hr = addZero(inputTime.hours);
    const min = addZero(inputTime.minutes);
    const sec = addZero(inputTime.seconds);
    const ms = addZero(inputTime.milliseconds, 3);

    if (inputTime.days > 0 || guideTime.days > 0) {
        const day = addZero(inputTime.days);
        return `${day}:${hr}:${min}:${sec}`;
    }
    if (inputTime.hours > 0 || guideTime.hours > 0) {
        return `${hr}:${min}:${sec}`;
    }
    if (displayMilliseconds) {
        return `${min}:${sec}:${ms}`;
    }

    return `${min}:${sec}`;
};

export default formatTime;
