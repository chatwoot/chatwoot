import { isSameYear, fromUnixTime, formatDistanceToNow, isSameDay } from 'date-fns';
import * as locales from 'date-fns/locale';

const selectedLocale = (locale = 'en') => {
  return locales[locale.replace('_', '')]; // Fallback para enUS se o localeKey não existir
};

/**
 * Formats a Unix timestamp into a human-readable time format.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='h:mm a'] - Desired format of the time.
 * @returns {string} Formatted time string.
 */
export const messageStamp = (time, fullDateTime = false, locale = 'en') => {
  const unixTime = fromUnixTime(time);
  let options;
  options = {
    timeStyle: 'medium',
  };
  if (fullDateTime) {
    options = {
      dateStyle: 'medium',
      timeStyle: 'medium',
    };
  }
  return new Intl.DateTimeFormat(locale, options).format(unixTime);
};

/**
 * Provides a formatted timestamp, adjusting the format based on the current year.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='MMM d, yyyy'] - Desired date format.
 * @returns {string} Formatted date string.
 */
export const messageTimestamp = (time, locale = 'en') => {
  const messageTime = fromUnixTime(time);
  const now = new Date();
  let options;
  if (isSameYear(messageTime, now)) {
    options = {
      dateStyle: 'medium',
      timeStyle: 'medium',
    };
    if (isSameDay(messageTime, now)) {
      options = {
        timeStyle: 'medium',
      };
    }
  } else {
    options = {
      dateStyle: 'medium',
    };
  }
  return new Intl.DateTimeFormat(locale.replace('_', '-'), options).format(
    messageTime
  );
};

/**
 * Converts a Unix timestamp to a relative time string (e.g., 3 hours ago).
 * @param {number} time - Unix timestamp.
 * @returns {string} Relative time string.
 */
export const dynamicTime = (time, locale) => {
  const unixTime = fromUnixTime(time);
  return formatDistanceToNow(unixTime, {
    addSuffix: true,
    locale: selectedLocale(locale),
  });
};

/**
 * Formats a Unix timestamp into a specified date format.
 * @param {number} time - Unix timestamp.
 * @param {string} [dateFormat='MMM d, yyyy'] - Desired date format.
 * @returns {string} Formatted date string.
 */
export const dateFormat = (time, locale = 'en') => {
  const unixTime = fromUnixTime(time);
  return new Intl.DateTimeFormat(locale.replace('_', '-'), {
    dateStyle: 'medium',
  }).format(unixTime);
};

/**
 * Converts a detailed time description into a shorter format, optionally appending 'ago'.
 * @param {string} time - Detailed time description (e.g., 'a minute ago').
 * @param {boolean} [withAgo=false] - Whether to append 'ago' to the result.
 * @returns {string} Shortened time description.
 */
export const shortTimestamp = (time, withAgo = false, locale = 'en') => {
  const unixTime = fromUnixTime(time);
  return formatDistanceToNow(unixTime, {
    addSuffix: withAgo,
    locale: selectedLocale(locale),
  });
};
