import fromUnixTime from 'date-fns/fromUnixTime';
import format from 'date-fns/format';

export const formatUnixDate = (date, dateFormat = 'MMM dd, yyyy') => {
  const unixDate = fromUnixTime(date);
  return format(unixDate, dateFormat);
};
