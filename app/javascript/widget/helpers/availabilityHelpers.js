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
// Accepts either utcOffset string ('+05:30') or timezone name ('Asia/Kolkata')
export const getDateWithOffset = utcOffsetOrTimezone =>
  utcToZonedTime(new Date().toISOString(), utcOffsetOrTimezone);

// Get working hours info for current time
export const getWorkingHoursInfo = (workingHours, utcOffset, enabled) => {
  if (!enabled) return { enabled: false, isInWorkingHours: true };

  const now = getDateWithOffset(utcOffset);
  const currentDay = now.getDay();
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();
  const currentTime = currentHour * MINUTES_IN_HOUR + currentMinute;

  // Find today's config
  const todayConfig =
    workingHours.find(slot => slot.day_of_week === currentDay) || {};

  // Check if all days are closed
  const allClosed = workingHours.every(slot => slot.closed_all_day);

  // Check if currently in working hours
  let isInWorkingHours = false;
  if (todayConfig.open_all_day) {
    isInWorkingHours = true;
  } else if (!todayConfig.closed_all_day) {
    const openTime =
      (todayConfig.open_hour || 0) * MINUTES_IN_HOUR +
      (todayConfig.open_minutes || 0);
    const closeTime =
      (todayConfig.close_hour || 0) * MINUTES_IN_HOUR +
      (todayConfig.close_minutes || 0);
    isInWorkingHours = currentTime >= openTime && currentTime < closeTime;
  }

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
  const dayMap = new Map(
    workingHours
      .filter(slot => !slot.closed_all_day)
      .map(slot => [slot.day_of_week, slot])
  );

  // First check the next 6 days
  for (let i = 1; i < DAYS_IN_WEEK; i += 1) {
    const day = (currentDay + i) % DAYS_IN_WEEK;
    const config = dayMap.get(day);
    if (config) {
      return { config, dayDiff: i };
    }
  }

  // The next available time is the same day next week
  const config = dayMap.get(currentDay);
  if (config) {
    return { config, dayDiff: DAYS_IN_WEEK };
  }

  return null;
};

// Calculate time until next opening
const calculateTimeUntil = (
  targetHour,
  targetMinute,
  currentHour,
  currentMinute
) => {
  let diffMinutes =
    targetHour * MINUTES_IN_HOUR +
    targetMinute -
    (currentHour * MINUTES_IN_HOUR + currentMinute);

  if (diffMinutes < 0) diffMinutes += HOURS_IN_DAY * MINUTES_IN_HOUR;

  return {
    hours: Math.floor(diffMinutes / MINUTES_IN_HOUR),
    minutes: diffMinutes % MINUTES_IN_HOUR,
  };
};

// Get next available time
export const getNextAvailableTime = (workingHoursInfo, locale) => {
  const { currentDay, currentHour, currentMinute, todayConfig, workingHours } =
    workingHoursInfo;

  if (!workingHours || workingHours.length === 0) {
    return { type: 'BACK_IN_SOME_TIME' };
  }

  // Check if we need next day
  const isAfterClose =
    todayConfig.close_hour && currentHour >= todayConfig.close_hour;
  let targetConfig = todayConfig;
  let dayDiff = 0;

  if (isAfterClose || todayConfig.closed_all_day) {
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
  const { hours, minutes } = calculateTimeUntil(
    targetHour,
    targetMinute,
    currentHour,
    currentMinute
  );

  // Format the response
  // Handle tomorrow first (before checking hours)
  if (dayDiff === 1) {
    return {
      type: 'BACK_ON',
      value: 'tomorrow',
    };
  }

  // Handle 2+ days away
  if (dayDiff > 1 || hours >= HOURS_IN_DAY) {
    return {
      type: 'BACK_ON',
      value: DAY_NAMES[targetConfig.day_of_week],
    };
  }

  // Same day - show time if 3+ hours away
  if (hours >= 3) {
    return {
      type: 'BACK_AT',
      value: getTime(targetHour, targetMinute),
    };
  }

  // Return relative time
  if (hours > 0) {
    const roundedHours = minutes > 0 ? hours + 1 : hours;
    return {
      type: 'BACK_IN',
      value: generateRelativeTime(roundedHours, 'hour', locale),
    };
  }

  if (minutes > 0) {
    const roundedMinutes = Math.ceil(minutes / 5) * 5;
    return {
      type: 'BACK_IN',
      value: generateRelativeTime(roundedMinutes, 'minutes', locale),
    };
  }

  return {
    type: 'BACK_IN_SOME_TIME',
  };
};
