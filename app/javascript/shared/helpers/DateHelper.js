import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';
import { endOfDay, getUnixTime, startOfDay, differenceInDays } from 'date-fns';

export const formatUnixDate = (date, dateFormat = 'MMM dd, yyyy') => {
  const unixDate = fromUnixTime(date);
  return format(unixDate, dateFormat);
};

export const formatDate = ({ date, todayText, yesterdayText }) => {
  const dateValue = new Date(date);
  if (isToday(dateValue)) return todayText;
  if (isYesterday(dateValue)) return yesterdayText;
  return date;
};

export const formatDigitToString = val => {
  return val > 9 ? `${val}` : `0${val}`;
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

export const getDayDifferenceFromNow = (now, timestampInSeconds) => {
  const date = new Date(timestampInSeconds * 1000);
  return differenceInDays(now, date);
};
