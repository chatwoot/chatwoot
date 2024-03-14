import { utcToZonedTime } from 'date-fns-tz';
// Array defining days of the week
const daysOfWeek = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

/**
 * Find the next available time for the specified day
 * @param {Object[]} workingHours - Array of objects representing working hours for each day
 * @param {number} dayOfWeek - Index of the day of the week (0 for Sunday, 1 for Monday, etc.)
 * @param {number} currentHour - Current hour of the day (24-hour format)
 * @param {number} currentMinutes - Current minutes of the hour
 * @returns {Object|null} - Object containing next available time information or null if not available
 */
const findNextAvailableTimeForDay = (
  workingHours,
  dayOfWeek,
  currentHour,
  currentMinutes
) => {
  const availableHours = workingHours.find(
    hours =>
      hours.day_of_week === dayOfWeek &&
      !hours.closed_all_day &&
      (currentHour < hours.close_hour ||
        (currentHour === hours.close_hour &&
          currentMinutes < hours.close_minutes))
  );

  if (availableHours) {
    return {
      hour: availableHours.open_hour,
      minutes: availableHours.open_minutes,
    };
  }

  return null;
};

/**
 * Find the next available time across days
 * @param {Object[]} workingHours - Array of objects representing working hours for each day
 * @param {number} currentDayOfWeek - Index of the current day of the week (0 for Sunday, 1 for Monday, etc.)
 * @returns {Object|null} - Object containing next available time information or null if not available
 */
const findNextAvailableTimeAcrossDays = (workingHours, currentDayOfWeek) => {
  const nextAvailableDays = workingHours.filter(hours => !hours.closed_all_day);
  for (let i = 0; i < 7; i += 1) {
    const nextDayIndex = (currentDayOfWeek + 1 + i) % 7;
    const nextDay = nextAvailableDays.find(
      hours => hours.day_of_week === nextDayIndex
    );
    if (nextDay) {
      return {
        hour: nextDay.open_hour,
        minutes: nextDay.open_minutes,
        day: nextDayIndex,
      };
    }
  }

  return null;
};

/**
 * Function to find the next available time
 * @param {Array} workingHours - Array of working hours for each day
 * @param {number} currentDayOfWeek - Index of the current day of the week (0 for Sunday, 1 for Monday, etc.)
 * @param {number} currentHour - Current hour of the day (24-hour format)
 * @param {number} currentMinutes - Current minutes of the hour
 * @returns {Object|null} - Object containing next available time information or null if not available
 */
const findNextAvailableTime = (
  workingHours,
  currentDayOfWeek,
  currentHour,
  currentMinutes
) => {
  const nextAvailableTimeToday = findNextAvailableTimeForDay(
    workingHours,
    currentDayOfWeek,
    currentHour,
    currentMinutes
  );

  if (nextAvailableTimeToday) {
    return { ...nextAvailableTimeToday, day: 'today' };
  }
  return findNextAvailableTimeAcrossDays(workingHours, currentDayOfWeek);
};

/**
 * Function to get the next availability message
 * @param {Array} workingHours - Array of working hours for each day
 * @param {Date} currentTime - Current time object
 * @returns {string} - Next availability message
 */
export const getNextAvailabilityMessage = (
  workingHours,
  currentTime,
  timezone = 'UTC'
) => {
  const utcZonedTime = utcToZonedTime(currentTime, timezone);
  const currentDayOfWeek = utcZonedTime.getDay();
  const currentHour = utcZonedTime.getHours();
  const currentMinutes = utcZonedTime.getMinutes();
  const nextAvailableTime = findNextAvailableTime(
    workingHours,
    currentDayOfWeek,
    currentHour,
    currentMinutes
  );

  // Calculate the time difference
  if (nextAvailableTime !== null) {
    const differenceInMinutes =
      nextAvailableTime.hour * 60 +
      nextAvailableTime.minutes -
      (currentHour * 60 + currentMinutes);
    const differenceInHours = Math.floor(differenceInMinutes / 60);

    // Check if the next available time is tomorrow
    if (nextAvailableTime.day === (currentDayOfWeek + 1) % 7) {
      return `We will be back online tomorrow`;
    }

    // Check if the next available time is on a specific day
    if (nextAvailableTime.day !== 'today') {
      return `We will be back online on ${daysOfWeek[nextAvailableTime.day]}`;
    }

    // Generate appropriate message based on time difference
    if (differenceInMinutes <= 1) {
      return 'We will be back online in less than a minute.';
    }
    if (differenceInMinutes < 60) {
      return `We will be back online in ${differenceInMinutes} minutes.`;
    }
    if (differenceInMinutes < 1440) {
      return `We will be back online in ${differenceInHours} hours`;
    }
  }
  return 'No available time found in working hours.';
};
