import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';
import isToday from 'date-fns/isToday';
import isYesterday from 'date-fns/isYesterday';
import parseISO from 'date-fns/parseISO';

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

export const buildDateFromTime = (hr, min, utcOffset, date = new Date()) => {
  const today = format(date, 'yyyy-MM-dd');
  const hour = formatDigitToString(hr);
  const minute = formatDigitToString(min);
  const timeString = `${today}T${hour}:${minute}:00${utcOffset}`;
  return parseISO(timeString);
};
