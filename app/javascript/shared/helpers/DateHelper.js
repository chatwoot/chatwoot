import moment from 'moment';

const DATE_FORMAT = 'MMM DD, YYYY';

export const formatDate = (dateTimeInSeconds, dateFormat = DATE_FORMAT) => {
  const date = moment(dateTimeInSeconds * 1000);
  return date.format(dateFormat);
};

export const getTimeInSeconds = () => {
  const timeInMillis = new Date().getTime();
  return Math.round(timeInMillis / 1000);
};
