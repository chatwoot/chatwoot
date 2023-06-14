import { getUnixTime, format, add } from 'date-fns';
import wootConstants from 'dashboard/constants/globals';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const findSnoozeTime = snoozeType => {
  let parsedDate = null;

  const currentDate = new Date();
  const addTime = time => {
    return new Date(
      currentDate.getFullYear(),
      currentDate.getMonth(),
      currentDate.getDate() + time,
      9,
      0,
      0,
      0
    );
  };

  if (snoozeType === SNOOZE_OPTIONS.AN_HOUR_FROM_NOW) {
    parsedDate = add(currentDate, { hours: 1 });
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_TOMORROW) {
    parsedDate = addTime(1);
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_WEEK) {
    parsedDate = addTime(7);
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_MONTH) {
    parsedDate = addTime(30);
  }

  return parsedDate ? getUnixTime(parsedDate) : null;
};
export const conversationReopenTime = snoozedUntil => {
  return snoozedUntil
    ? format(new Date(snoozedUntil), 'eee, d MMM, h.mmaaa')
    : null;
};
