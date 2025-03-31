import isValid from "../isValid/index.js";
import isWeekend from "../isWeekend/index.js";
import toDate from "../toDate/index.js";
import differenceInCalendarDays from "../differenceInCalendarDays/index.js";
import addDays from "../addDays/index.js";
import isSameDay from "../isSameDay/index.js";
import toInteger from "../_lib/toInteger/index.js";
import requiredArgs from "../_lib/requiredArgs/index.js";
/**
 * @name differenceInBusinessDays
 * @category Day Helpers
 * @summary Get the number of business days between the given dates.
 *
 * @description
 * Get the number of business day periods between the given dates.
 * Business days being days that arent in the weekend.
 * Like `differenceInCalendarDays`, the function removes the times from
 * the dates before calculating the difference.
 *
 * @param {Date|Number} dateLeft - the later date
 * @param {Date|Number} dateRight - the earlier date
 * @returns {Number} the number of business days
 * @throws {TypeError} 2 arguments required
 *
 * @example
 * // How many business days are between
 * // 10 January 2014 and 20 July 2014?
 * var result = differenceInBusinessDays(
 *   new Date(2014, 6, 20),
 *   new Date(2014, 0, 10)
 * )
 * //=> 136
 */

export default function differenceInBusinessDays(dirtyDateLeft, dirtyDateRight) {
  requiredArgs(2, arguments);
  var dateLeft = toDate(dirtyDateLeft);
  var dateRight = toDate(dirtyDateRight);
  if (!isValid(dateLeft) || !isValid(dateRight)) return new Date(NaN);
  var calendarDifference = differenceInCalendarDays(dateLeft, dateRight);
  var sign = calendarDifference < 0 ? -1 : 1;
  var weeks = toInteger(calendarDifference / 7);
  var result = weeks * 5;
  dateRight = addDays(dateRight, weeks * 7); // the loop below will run at most 6 times to account for the remaining days that don't makeup a full week

  while (!isSameDay(dateLeft, dateRight)) {
    // sign is used to account for both negative and positive differences
    result += isWeekend(dateRight) ? 0 : sign;
    dateRight = addDays(dateRight, sign);
  }

  return result === 0 ? 0 : result;
}