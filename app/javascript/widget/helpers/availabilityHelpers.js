import { getTime } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { utcToZonedTime } from 'date-fns-tz';
import { generateRelativeTime } from 'shared/helpers/DateHelper';

const DAYS_IN_WEEK = 7;
const HOURS_IN_DAY = 24;
const MINUTES_IN_HOUR = 60;
const DAY_NAMES = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

// Get current date with UTC offset or timezone
export const getDateWithOffset = utcOffsetOrTimezone =>
  utcToZonedTime(new Date().toISOString(), utcOffsetOrTimezone);

// Helper to convert time to minutes
const timeToMinutes = (hours = 0, minutes = 0) =>
  hours * MINUTES_IN_HOUR + minutes;

// Check if current time is within open hours
const isWithinOpenHours = (currentMinutes, openMinutes, closeMinutes) =>
  currentMinutes >= openMinutes && currentMinutes < closeMinutes;

// Get working hours info for current time
export const getWorkingHoursInfo = (workingHours, utcOffset, enabled) => {
  if (!enabled) return { enabled: false, isInWorkingHours: true };

  const now = getDateWithOffset(utcOffset);
  const currentDay = now.getDay();
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();

  const todayConfig =
    workingHours.find(slot => slot.day_of_week === currentDay) || {};
  const allClosed = workingHours.every(slot => slot.closed_all_day);

  // Determine if currently in working hours
  const isInWorkingHours =
    todayConfig.open_all_day ||
    (!todayConfig.closed_all_day &&
      isWithinOpenHours(
        timeToMinutes(currentHour, currentMinute),
        timeToMinutes(todayConfig.open_hour, todayConfig.open_minutes),
        timeToMinutes(todayConfig.close_hour, todayConfig.close_minutes)
      ));

  return {
    enabled: true,
    allClosed,
    isInWorkingHours,
    currentDay,
    currentHour,
    currentMinute,
    todayConfig,
    workingHours,
  };
};

// Get next working day
const getNextWorkingDay = (workingHours, currentDay) => {
  const openDays = new Map(
    workingHours
      .filter(slot => !slot.closed_all_day)
      .map(slot => [slot.day_of_week, slot])
  );

  // Check next 6 days
  for (let i = 1; i < DAYS_IN_WEEK; i += 1) {
    const day = (currentDay + i) % DAYS_IN_WEEK;
    const config = openDays.get(day);
    if (config) return { config, dayDiff: i };
  }

  // Check same day next week
  const config = openDays.get(currentDay);
  return config ? { config, dayDiff: DAYS_IN_WEEK } : null;
};

// Calculate time difference in hours and minutes
const calculateTimeDifference = (
  targetHour,
  targetMinute,
  currentHour,
  currentMinute
) => {
  let diffMinutes =
    timeToMinutes(targetHour, targetMinute) -
    timeToMinutes(currentHour, currentMinute);

  if (diffMinutes < 0) diffMinutes += HOURS_IN_DAY * MINUTES_IN_HOUR;

  return {
    hours: Math.floor(diffMinutes / MINUTES_IN_HOUR),
    minutes: diffMinutes % MINUTES_IN_HOUR,
  };
};

// Format time based on difference
const formatTimeResponse = (dayDiff, hours, minutes, targetConfig, locale) => {
  // Tomorrow
  if (dayDiff === 1) {
    return { type: 'BACK_ON', value: 'tomorrow' };
  }

  // Multiple days away
  if (dayDiff > 1 || hours >= HOURS_IN_DAY) {
    return { type: 'BACK_ON', value: DAY_NAMES[targetConfig.day_of_week] };
  }

  // Same day, specific time
  if (hours >= 3) {
    const targetHour = targetConfig.open_all_day
      ? 0
      : targetConfig.open_hour || 0;
    const targetMinute = targetConfig.open_minutes || 0;
    return { type: 'BACK_AT', value: getTime(targetHour, targetMinute) };
  }

  // Relative hours
  if (hours > 0) {
    const roundedHours = minutes > 0 ? hours + 1 : hours;
    return {
      type: 'BACK_IN',
      value: generateRelativeTime(roundedHours, 'hour', locale),
    };
  }

  // Relative minutes
  if (minutes > 0) {
    const roundedMinutes = Math.ceil(minutes / 5) * 5;
    return {
      type: 'BACK_IN',
      value: generateRelativeTime(roundedMinutes, 'minutes', locale),
    };
  }

  return { type: 'BACK_IN_SOME_TIME' };
};

// Get next available time
export const getNextAvailableTime = (workingHoursInfo, locale) => {
  const { currentDay, currentHour, currentMinute, todayConfig, workingHours } =
    workingHoursInfo;

  if (!workingHours?.length) {
    return { type: 'BACK_IN_SOME_TIME' };
  }

  // Determine if we need to check next day
  const needsNextDay =
    todayConfig.closed_all_day ||
    (todayConfig.close_hour && currentHour >= todayConfig.close_hour);

  // Get target day configuration
  let targetConfig = todayConfig;
  let dayDiff = 0;

  if (needsNextDay) {
    const next = getNextWorkingDay(workingHours, currentDay);
    if (!next) return { type: 'BACK_IN_SOME_TIME' };
    targetConfig = next.config;
    dayDiff = next.dayDiff;
  }

  // Calculate time difference
  const targetHour = targetConfig.open_all_day
    ? 0
    : targetConfig.open_hour || 0;
  const targetMinute = targetConfig.open_minutes || 0;
  const { hours, minutes } = calculateTimeDifference(
    targetHour,
    targetMinute,
    currentHour,
    currentMinute
  );

  return formatTimeResponse(dayDiff, hours, minutes, targetConfig, locale);
};
