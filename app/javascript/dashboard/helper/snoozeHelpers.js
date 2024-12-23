import {
  getUnixTime,
  format,
  add,
  startOfWeek,
  addWeeks,
  startOfMonth,
  isMonday,
  isToday,
  setHours,
  setMinutes,
  setSeconds,
} from 'date-fns';
import wootConstants from 'dashboard/constants/globals';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const findStartOfNextWeek = currentDate => {
  const startOfNextWeek = startOfWeek(addWeeks(currentDate, 1));
  return isMonday(startOfNextWeek)
    ? startOfNextWeek
    : add(startOfNextWeek, {
        days: (8 - startOfNextWeek.getDay()) % 7,
      });
};

export const findStartOfNextMonth = currentDate => {
  const startOfNextMonth = startOfMonth(add(currentDate, { months: 1 }));
  return isMonday(startOfNextMonth)
    ? startOfNextMonth
    : add(startOfNextMonth, {
        days: (8 - startOfNextMonth.getDay()) % 7,
      });
};

export const findNextDay = currentDate => {
  return add(currentDate, { days: 1 });
};

export const setHoursToNine = date => {
  return setSeconds(setMinutes(setHours(date, 9), 0), 0);
};

export const findSnoozeTime = (snoozeType, currentDate = new Date()) => {
  let parsedDate = null;
  if (snoozeType === SNOOZE_OPTIONS.AN_HOUR_FROM_NOW) {
    parsedDate = add(currentDate, { hours: 1 });
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_TOMORROW) {
    parsedDate = setHoursToNine(findNextDay(currentDate));
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_WEEK) {
    parsedDate = setHoursToNine(findStartOfNextWeek(currentDate));
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_MONTH) {
    parsedDate = setHoursToNine(findStartOfNextMonth(currentDate));
  }

  return parsedDate ? getUnixTime(parsedDate) : null;
};
export const snoozedReopenTime = snoozedUntil => {
  if (!snoozedUntil) {
    return null;
  }
  const date = new Date(snoozedUntil);

  if (isToday(date)) {
    return format(date, 'h.mmaaa');
  }
  return snoozedUntil ? format(date, 'd MMM, h.mmaaa') : null;
};

export const snoozedReopenTimeToTimestamp = snoozedUntil => {
  return snoozedUntil ? getUnixTime(new Date(snoozedUntil)) : null;
};
export const shortenSnoozeTime = snoozedUntil => {
  if (!snoozedUntil) {
    return null;
  }
  const unitMap = {
    minutes: 'm',
    minute: 'm',
    hours: 'h',
    hour: 'h',
    days: 'd',
    day: 'd',
    months: 'mo',
    month: 'mo',
    years: 'y',
    year: 'y',
  };
  const shortenTime = snoozedUntil
    .replace(/^in\s+/i, '')
    .replace(
      /\s(minute|hour|day|month|year)s?\b/gi,
      (match, unit) => unitMap[unit.toLowerCase()] || match
    );

  return shortenTime;
};
