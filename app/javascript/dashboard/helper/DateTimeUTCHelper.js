/**
 * Applies time to a UTC timestamp
 * @param {number|null} timestamp - UTC timestamp in milliseconds
 * @param {string} timeString - Time string in format "HH:MM"
 * @returns {number|null} UTC timestamp with applied time or null
 */
export const applyTimeUTC = (timestamp, timeString) => {
  if (timestamp == null) return null;

  const d = new Date(timestamp);
  const [h, m] = timeString.split(':').map(Number);

  const utcTimestamp = Date.UTC(
    d.getUTCFullYear(),
    d.getUTCMonth(),
    d.getUTCDate(),
    h,
    m,
    0,
    0
  );

  return utcTimestamp;
};

/**
 * Converts a Date object to UTC timestamp at start of day (00:00:00)
 * @param {Date} date - Date object
 * @returns {number|null} UTC timestamp in milliseconds
 */
export const dateToUTCTimestamp = date => {
  if (!(date instanceof Date)) return null;

  return Date.UTC(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    0,
    0,
    0,
    0
  );
};

/**
 * Converts a Date object to UTC timestamp at end of day (23:59:59)
 * @param {Date} date - Date object
 * @returns {number|null} UTC timestamp in milliseconds
 */
export const dateToUTCTimestampEndOfDay = date => {
  if (!(date instanceof Date)) return null;

  return Date.UTC(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    23,
    59,
    59,
    999
  );
};
