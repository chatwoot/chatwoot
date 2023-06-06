import { getUnixTime } from 'date-fns';
import * as chrono from 'chrono-node';

export const findSnoozeTime = snoozeType => {
  const parsedDate = chrono.parseDate(snoozeType);
  return parsedDate ? getUnixTime(parsedDate) : null;
};
