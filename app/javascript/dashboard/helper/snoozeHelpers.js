import { getUnixTime, format, add } from 'date-fns';
import wootConstants from 'dashboard/constants/globals';

const SNOOZE_OPTIONS = wootConstants.SNOOZE_OPTIONS;

export const findSnoozeTime = snoozeType => {
  let parsedDate = null;
  const currentDate = new Date();
  if (snoozeType === SNOOZE_OPTIONS.AN_HOUR_FROM_NOW) {
    parsedDate = add(currentDate, { hours: 1 });
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_TOMORROW) {
    parsedDate = add(currentDate, { days: 1 });
    parsedDate.setHours(9, 0, 0, 0);
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_WEEK) {
    parsedDate = add(currentDate, { weeks: 1 });
    parsedDate.setHours(9, 0, 0, 0);
  } else if (snoozeType === SNOOZE_OPTIONS.UNTIL_NEXT_MONTH) {
    parsedDate = add(currentDate, { months: 1 });
    parsedDate.setHours(9, 0, 0, 0);
  }

  return parsedDate ? getUnixTime(parsedDate) : null;
};
export const conversationReopenTime = snoozedUntil => {
  return snoozedUntil
    ? format(new Date(snoozedUntil), 'eee, d MMM, h.mmaaa')
    : null;
};
