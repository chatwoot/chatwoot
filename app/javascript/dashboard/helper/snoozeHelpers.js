import { getUnixTime, format } from 'date-fns';
import * as chrono from 'chrono-node';

export const findSnoozeTime = snoozeType => {
  const parsedDate = chrono.parseDate(snoozeType);
  return parsedDate ? getUnixTime(parsedDate) : null;
};

export const conversationReopenTime = snoozedUntil => {
  return snoozedUntil
    ? format(new Date(snoozedUntil), 'eee, d MMM, h.mmaaa')
    : null;
};
