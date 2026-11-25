import fromUnixTime from 'date-fns/fromUnixTime';
import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';
import { endOfDay, getUnixTime, startOfDay } from 'date-fns';
import { formatFixed, formatLocalized } from './localizedDate';

export const formatUnixDate = (date, dateFormat = 'MMM dd, yyyy') => {
  // A grouping key that `formatDate` parses back, so it stays in English.
  return formatFixed(fromUnixTime(date), dateFormat);
};

export const formatDate = ({ date, todayText, yesterdayText }) => {
  const dateValue = new Date(date);
  if (isToday(dateValue)) return todayText;
  if (isYesterday(dateValue)) return yesterdayText;
  return formatLocalized(dateValue, 'MMM dd, yyyy');
};

export const isTimeAfter = (h1, m1, h2, m2) => {
  if (h1 < h2) {
    return false;
  }

  if (h1 === h2) {
    return m1 >= m2;
  }

  return true;
};

/** Get start of day as a UNIX timestamp */
export const getUnixStartOfDay = date => getUnixTime(startOfDay(date));

/** Get end of day as a UNIX timestamp */
export const getUnixEndOfDay = date => getUnixTime(endOfDay(date));

export const generateRelativeTime = (value, unit, languageCode) => {
  const code = languageCode?.replace(/_/g, '-'); // Hacky fix we need to handle it from source
  const rtf = new Intl.RelativeTimeFormat(code, {
    numeric: 'auto',
  });
  return rtf.format(value, unit);
};
