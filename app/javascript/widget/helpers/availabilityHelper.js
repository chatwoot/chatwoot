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
  let nextAvailableDays = [];
  let nextAvailableTime = null;

  // Find the next available time for today
  const nextAvailableTimeToday = workingHours.find(
    workingHour =>
      currentDayOfWeek === workingHour.day_of_week && // Match current day
      !workingHour.closed_all_day && // Check if not closed for the whole day
      (currentHour < workingHour.close_hour || // Check if current hour is before closing hour
        (currentHour === workingHour.close_hour && // or if hours are equal but minutes are before closing minutes
          currentMinutes < workingHour.close_minutes))
  );
  // If next available time for today is found
  if (nextAvailableTimeToday) {
    nextAvailableTime = {
      hour: nextAvailableTimeToday.open_hour,
      minutes: nextAvailableTimeToday.open_minutes,
      day: 'today',
    };
  }

  // If no available time for today, find the next available time for the next day(s)
  if (nextAvailableTime === null) {
    nextAvailableDays = workingHours.filter(hours => !hours.closed_all_day);

    for (let i = 0; i < 7; i += 1) {
      const nextDayIndex = (currentDayOfWeek + 1 + i) % 7;
      const nextDay = nextAvailableDays.find(
        hours => hours.day_of_week === nextDayIndex
      );
      if (nextDay) {
        nextAvailableTime = {
          hour: nextDay.open_hour,
          minutes: nextDay.open_minutes,
          day: nextDayIndex,
        };
        break;
      }
    }
  }

  return nextAvailableTime;
};

/**
 * Function to get the next availability message
 * @param {Array} workingHours - Array of working hours for each day
 * @param {Date} currentTime - Current time object
 * @returns {string} - Next availability message
 */
export const getNextAvailabilityMessage = (workingHours, currentTime) => {
  const currentDayOfWeek = currentTime.getDay();
  const currentHour = currentTime.getHours();
  const currentMinutes = currentTime.getMinutes();
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
