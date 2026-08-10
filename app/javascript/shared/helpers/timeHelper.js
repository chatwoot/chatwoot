import {
  format,
  isSameYear,
  isThisYear,
  isToday,
  isYesterday,
  fromUnixTime,
  formatDistanceToNow,
  differenceInDays,
} from 'date-fns';

const getLocalizedDateOptions = dateFormat => {
  const options = {
    'h:mm a': {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    },
    'LLL d, h:mm a': {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    },
    'LLL d y, h:mm a': {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    },
    'LLL d yyyy, h:mm a': {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    },
    'MMM d, yyyy': {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    },
    'LLL d, yyyy': {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    },
  };

  return options[dateFormat];
};

const formatLocalizedDate = (date, dateFormat, localeCode) => {
  const options = getLocalizedDateOptions(dateFormat);
  if (!localeCode || !options) return format(date, dateFormat);

  return new Intl.DateTimeFormat(localeCode, options).format(date);
};

const getRelativeTimeParts = time => {
  const normalizedTime = time.replace(/about|over|almost/g, '').trim();
  const direction = normalizedTime.startsWith('in ') ? 1 : -1;
  const cleanedTime = normalizedTime
    .replace(/^in\s+/, '')
    .replace(/\s+ago$/, '')
    .trim();

  const singularMappings = {
    'less than a minute': [0, 'second'],
    'a minute': [1, 'minute'],
    'an hour': [1, 'hour'],
    'a day': [1, 'day'],
    'a month': [1, 'month'],
    'a year': [1, 'year'],
  };

  if (singularMappings[cleanedTime]) {
    const [value, unit] = singularMappings[cleanedTime];
    return { value: value * direction, unit };
  }

  const match = cleanedTime.match(
    /^(\d+)\s+(minute|minutes|hour|hours|day|days|month|months|year|years)$/
  );

  if (!match) return null;

  const [, value, unit] = match;
  return {
    value: Number(value) * direction,
    unit: unit.replace(/s$/, ''),
  };
};

/**
 * Formats a Unix timestamp into a human-readable time format.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='h:mm a'] - Desired format of the time.
 * @param {string} [localeCode] - Locale code for date formatting.
 * @returns {string} Formatted time string.
 */
export const messageStamp = (
  time,
  dateFormat = 'h:mm a',
  localeCode = null
) => {
  const unixTime = fromUnixTime(time);
  return formatLocalizedDate(unixTime, dateFormat, localeCode);
};

/**
 * Provides a formatted timestamp, adjusting the format based on the current year.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='MMM d, yyyy'] - Desired date format.
 * @param {string} [localeCode] - Locale code for date formatting.
 * @returns {string} Formatted date string.
 */
export const messageTimestamp = (
  time,
  dateFormat = 'MMM d, yyyy',
  localeCode = null
) => {
  const messageTime = fromUnixTime(time);
  const now = new Date();
  const messageDate = formatLocalizedDate(messageTime, dateFormat, localeCode);
  if (!isSameYear(messageTime, now)) {
    return formatLocalizedDate(messageTime, 'LLL d y, h:mm a', localeCode);
  }
  return messageDate;
};

/**
 * Formats a Unix timestamp relative to today: the time for today, a caller-
 * supplied label for yesterday, and a date otherwise. The yesterday label is
 * passed in so the caller keeps ownership of translation.
 * @param {number} time - Unix timestamp.
 * @param {string} yesterdayLabel - Localized label shown for yesterday.
 * @returns {string} Formatted timestamp string.
 */
export const relativeDayTimestamp = (time, yesterdayLabel) => {
  const date = fromUnixTime(time);
  if (isToday(date)) return format(date, 'h:mm a');
  if (isYesterday(date)) return yesterdayLabel;
  if (isThisYear(date)) return format(date, 'MMM d');
  return format(date, 'MMM d, yyyy');
};

/**
 * Converts a Unix timestamp to a relative time string (e.g., 3 hours ago).
 * @param {number} time - Unix timestamp.
 * @returns {string} Relative time string.
 */
export const dynamicTime = time => {
  const unixTime = fromUnixTime(time);
  return formatDistanceToNow(unixTime, { addSuffix: true });
};

/**
 * Formats a Unix timestamp into a specified date format.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='MMM d, yyyy'] - Desired date format.
 * @param {string} [localeCode] - Locale code for date formatting.
 * @returns {string} Formatted date string.
 */
export const dateFormat = (time, df = 'MMM d, yyyy', localeCode = null) => {
  const unixTime = fromUnixTime(time);
  return formatLocalizedDate(unixTime, df, localeCode);
};

/**
 * Converts a detailed time description into a shorter format, optionally appending 'ago'.
 * @param {string} time - Detailed time description (e.g., 'a minute ago').
 * @param {boolean} [withAgo=false] - Whether to append 'ago' to the result.
 * @param {string} [localeCode] - Locale code for timestamp formatting.
 * @returns {string} Shortened time description.
 */
export const shortTimestamp = (time, withAgo = false, localeCode = null) => {
  if (localeCode && !localeCode.toLowerCase().startsWith('en')) {
    const relativeTime = getRelativeTimeParts(time);
    if (relativeTime) {
      return new Intl.RelativeTimeFormat(localeCode, {
        numeric: relativeTime.value === 0 ? 'auto' : 'always',
      }).format(relativeTime.value, relativeTime.unit);
    }
  }

  // This function takes a time string and converts it to a short time string
  // with the following format: 1m, 1h, 1d, 1mo, 1y
  // The function also takes an optional boolean parameter withAgo
  // which will add the word "ago" to the end of the time string
  const suffix = withAgo ? ' ago' : '';
  const timeMappings = {
    'less than a minute ago': 'now',
    'in less than a minute': 'now',
    'a minute ago': `1m${suffix}`,
    'an hour ago': `1h${suffix}`,
    'a day ago': `1d${suffix}`,
    'a month ago': `1mo${suffix}`,
    'a year ago': `1y${suffix}`,
  };
  // Check if the time string is one of the specific cases
  if (timeMappings[time]) {
    return timeMappings[time];
  }
  const convertToShortTime = time
    .replace(/about|over|almost|/g, '')
    .replace(' minute ago', `m${suffix}`)
    .replace(' minutes ago', `m${suffix}`)
    .replace(' hour ago', `h${suffix}`)
    .replace(' hours ago', `h${suffix}`)
    .replace(' day ago', `d${suffix}`)
    .replace(' days ago', `d${suffix}`)
    .replace(' month ago', `mo${suffix}`)
    .replace(' months ago', `mo${suffix}`)
    .replace(' year ago', `y${suffix}`)
    .replace(' years ago', `y${suffix}`);
  return convertToShortTime;
};

/**
 * Formats a duration in seconds into mm:ss or hh:mm:ss.
 * @param {number|string} durationInSeconds - Duration in seconds.
 * @returns {string} Formatted duration string. Empty string for invalid input.
 */
export const formatDuration = durationInSeconds => {
  if (durationInSeconds === null || durationInSeconds === undefined) return '';

  const totalSeconds = Number(durationInSeconds);
  if (Number.isNaN(totalSeconds) || totalSeconds < 0) return '';

  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  const mm = minutes.toString().padStart(2, '0');
  const ss = seconds.toString().padStart(2, '0');
  if (hours > 0) {
    return `${hours.toString().padStart(2, '0')}:${mm}:${ss}`;
  }
  return `${mm}:${ss}`;
};

/**
 * Calculates the difference in days between now and a given timestamp.
 * @param {Date} now - Current date/time.
 * @param {number} timestampInSeconds - Unix timestamp in seconds.
 * @returns {number} Number of days difference.
 */
export const getDayDifferenceFromNow = (now, timestampInSeconds) => {
  const date = new Date(timestampInSeconds * 1000);
  return differenceInDays(now, date);
};

/**
 * Checks if more than 24 hours have passed since a given timestamp.
 * Useful for determining if retry/refresh actions should be disabled.
 * @param {number} timestamp - Unix timestamp.
 * @returns {boolean} True if more than 24 hours have passed.
 */
export const hasOneDayPassed = timestamp => {
  if (!timestamp) return true; // Defensive check
  return getDayDifferenceFromNow(new Date(), timestamp) >= 1;
};
