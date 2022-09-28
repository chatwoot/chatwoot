import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';

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
