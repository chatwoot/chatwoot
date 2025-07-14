export const parseDuration = (str) => {
  const SECONDS_IN_YEAR = 365 * 24 * 60 * 60;
  const SECONDS_IN_MONTH = 30 * 24 * 60 * 60;
  const SECONDS_IN_DAY = 24 * 60 * 60;
  const SECONDS_IN_HOUR = 60 * 60;
  const SECONDS_IN_MIN = 60;

  // P10Y10M10DT10H10M10.1S
  const durationRegex =
    /P(?:(\d*)Y)?(?:(\d*)M)?(?:(\d*)D)?(?:T(?:(\d*)H)?(?:(\d*)M)?(?:([\d.]*)S)?)?/;
  const match = durationRegex.exec(str);

  if (!match) {
    return 0;
  }

  const [year, month, day, hour, minute, second] = match.slice(1);

  return (parseFloat(year || 0) * SECONDS_IN_YEAR +
    parseFloat(month || 0) * SECONDS_IN_MONTH +
    parseFloat(day || 0) * SECONDS_IN_DAY +
    parseFloat(hour || 0) * SECONDS_IN_HOUR +
    parseFloat(minute || 0) * SECONDS_IN_MIN +
    parseFloat(second || 0));
};

export const parseDate = (str) => {
  // Date format without timezone according to ISO 8601
  // YYY-MM-DDThh:mm:ss.ssssss
  const dateRegex = /^\d+-\d+-\d+T\d+:\d+:\d+(\.\d+)?$/;

  // If the date string does not specifiy a timezone, we must specifiy UTC. This is
  // expressed by ending with 'Z'
  if (dateRegex.test(str)) {
    str += 'Z';
  }

  return Date.parse(str);
};
