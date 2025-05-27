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

// Convert hours and minutes to minutes
const timeToMinutes = (hours = 0, minutes = 0) =>
  hours * MINUTES_IN_HOUR + minutes;

// Check if current time is within open hours
const isWithinOpenHours = (currentMinutes, openMinutes, closeMinutes) =>
  currentMinutes >= openMinutes && currentMinutes < closeMinutes;

// Check if today's config is open
const checkWorkingHours = (todayConfig, currentHour, currentMinute) => {
  if (todayConfig.open_all_day) return true;
  if (todayConfig.closed_all_day) return false;

  return isWithinOpenHours(
    timeToMinutes(currentHour, currentMinute),
    timeToMinutes(todayConfig.open_hour, todayConfig.open_minutes),
    timeToMinutes(todayConfig.close_hour, todayConfig.close_minutes)
  );
};

// Get working hours info for current time
export const getWorkingHoursInfo = (workingHours, utcOffset, enabled) => {
  if (!enabled) return { enabled: false, isInWorkingHours: true };

  const now = getDateWithOffset(utcOffset);
  const currentDay = now.getDay();
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();

  const todayConfig =
    workingHours.find(slot => slot.day_of_week === currentDay) ?? {};
  const allClosed = workingHours.every(slot => slot.closed_all_day);
  const isInWorkingHours = checkWorkingHours(
    todayConfig,
    currentHour,
    currentMinute
  );

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

// Get response for multiple days (Tomorrow, Next Monday, etc.)
const getResponseForMultipleDays = (dayDiff, hours, targetConfig) => {
  if (dayDiff === 1) return { type: 'BACK_ON', value: 'tomorrow' };
  if (dayDiff > 1 || hours >= HOURS_IN_DAY) {
    return { type: 'BACK_ON', value: DAY_NAMES[targetConfig.day_of_week] };
  }
  return null;
};

// Get response for specific time (9:30 AM)
const getSpecificTimeResponse = targetConfig => {
  const targetHour = targetConfig.open_all_day
    ? 0
    : (targetConfig.open_hour ?? 0);
  const targetMinute = targetConfig.open_minutes ?? 0;
  return { type: 'BACK_AT', value: getTime(targetHour, targetMinute) };
};

// Get response for relative hours (in 2 hours)
const getRelativeHoursResponse = (hours, minutes, locale) => {
  const roundedHours = minutes > 0 ? hours + 1 : hours;
  return {
    type: 'BACK_IN',
    value: generateRelativeTime(roundedHours, 'hour', locale),
  };
};

// Get response for relative minutes (in 15 minutes)
const getRelativeMinutesResponse = (minutes, locale) => {
  const roundedMinutes = Math.ceil(minutes / 5) * 5;
  return {
    type: 'BACK_IN',
    value: generateRelativeTime(roundedMinutes, 'minutes', locale),
  };
};

// Get response for same day (9:30 AM, in 2 hours, in 15 minutes, etc.)
const getResponseForSameDay = (hours, minutes, targetConfig, locale) => {
  if (hours >= 3) return getSpecificTimeResponse(targetConfig);
  if (hours > 0) return getRelativeHoursResponse(hours, minutes, locale);
  if (minutes > 0) return getRelativeMinutesResponse(minutes, locale);
  return { type: 'BACK_IN_SOME_TIME' };
};

const formatTimeResponse = (dayDiff, hours, minutes, targetConfig, locale) => {
  const multipleDayResponse = getResponseForMultipleDays(
    dayDiff,
    hours,
    targetConfig
  );
  return (
    multipleDayResponse ??
    getResponseForSameDay(hours, minutes, targetConfig, locale)
  );
};

const getTargetConfig = (
  todayConfig,
  workingHours,
  currentDay,
  currentHour
) => {
  const needsNextDay =
    todayConfig.closed_all_day ||
    (todayConfig.close_hour && currentHour >= todayConfig.close_hour);

  if (!needsNextDay) {
    return { targetConfig: todayConfig, dayDiff: 0 };
  }

  const next = getNextWorkingDay(workingHours, currentDay);
  return next ? { targetConfig: next.config, dayDiff: next.dayDiff } : null;
};

const calculateTargetTime = targetConfig => ({
  targetHour: targetConfig.open_all_day ? 0 : (targetConfig.open_hour ?? 0),
  targetMinute: targetConfig.open_minutes ?? 0,
});

export const getNextAvailableTime = (workingHoursInfo, locale) => {
  const { currentDay, currentHour, currentMinute, todayConfig, workingHours } =
    workingHoursInfo;

  if (!workingHours?.length) return { type: 'BACK_IN_SOME_TIME' };

  const configInfo = getTargetConfig(
    todayConfig,
    workingHours,
    currentDay,
    currentHour
  );
  if (!configInfo) return { type: 'BACK_IN_SOME_TIME' };

  const { targetConfig, dayDiff } = configInfo;
  const { targetHour, targetMinute } = calculateTargetTime(targetConfig);
  const { hours, minutes } = calculateTimeDifference(
    targetHour,
    targetMinute,
    currentHour,
    currentMinute
  );

  return formatTimeResponse(dayDiff, hours, minutes, targetConfig, locale);
};
