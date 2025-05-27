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

// Convert time to minutes
const toMinutes = (hours = 0, minutes = 0) => hours * MINUTES_IN_HOUR + minutes;

// Check if time is within range
const isInRange = (current, start, end) => current >= start && current < end;

// Get working hours info for current time
export const getWorkingHoursInfo = (workingHours, utcOffset, enabled) => {
  if (!enabled) return { enabled: false, isInWorkingHours: true };

  const now = getDateWithOffset(utcOffset);
  const currentDay = now.getDay();
  const currentTime = toMinutes(now.getHours(), now.getMinutes());

  const todayConfig =
    workingHours.find(slot => slot.day_of_week === currentDay) ?? {};
  const allClosed = workingHours.every(slot => slot.closed_all_day);

  const isInWorkingHours =
    todayConfig.open_all_day ||
    (!todayConfig.closed_all_day &&
      isInRange(
        currentTime,
        toMinutes(todayConfig.open_hour, todayConfig.open_minutes),
        toMinutes(todayConfig.close_hour, todayConfig.close_minutes)
      ));

  return {
    enabled: true,
    allClosed,
    isInWorkingHours: Boolean(isInWorkingHours),
    currentDay,
    currentHour: now.getHours(),
    currentMinute: now.getMinutes(),
    todayConfig,
    workingHours,
  };
};

// Find next open slot
const findNextOpenSlot = (workingHours, currentDay) => {
  const openSlots = workingHours.filter(slot => !slot.closed_all_day);

  // Check next 7 days
  for (let i = 1; i <= DAYS_IN_WEEK; i += 1) {
    const day = (currentDay + i) % DAYS_IN_WEEK;
    const slot = openSlots.find(s => s.day_of_week === day);
    if (slot) return { config: slot, dayDiff: i };
  }

  return null;
};

// Calculate time until target
const getTimeDifference = (targetTime, currentTime) => {
  const diff = targetTime - currentTime;
  const adjustedDiff = diff < 0 ? diff + HOURS_IN_DAY * MINUTES_IN_HOUR : diff;

  return {
    hours: Math.floor(adjustedDiff / MINUTES_IN_HOUR),
    minutes: adjustedDiff % MINUTES_IN_HOUR,
  };
};

// Format response based on time difference
const formatTimeResponse = ({ dayDiff, hours, minutes, config, locale }) => {
  // Multiple days away (Tomorrow)
  if (dayDiff === 1) return { type: 'BACK_ON', value: 'tomorrow' };
  // Multiple days away (Next Monday)
  if (dayDiff > 1 || hours >= HOURS_IN_DAY) {
    return { type: 'BACK_ON', value: DAY_NAMES[config.day_of_week] };
  }

  // Same day (9:30 AM)
  if (hours >= 3) {
    const targetHour = config.open_all_day ? 0 : (config.open_hour ?? 0);
    const targetMinute = config.open_minutes ?? 0;
    return { type: 'BACK_AT', value: getTime(targetHour, targetMinute) };
  }
  // Same day (in 2 hours)
  if (hours > 0) {
    const roundedHours = minutes > 0 ? hours + 1 : hours;
    return {
      type: 'BACK_IN',
      value: generateRelativeTime(roundedHours, 'hour', locale),
    };
  }
  // Same day (in 15 minutes)
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
export const getNextAvailableTime = (
  { currentDay, currentHour, currentMinute, todayConfig, workingHours },
  locale
) => {
  if (!workingHours?.length) return { type: 'BACK_IN_SOME_TIME' };

  const currentTime = toMinutes(currentHour, currentMinute);

  // Check if we need to find next day
  const needsNextDay =
    todayConfig.closed_all_day ||
    (todayConfig.close_hour && currentHour >= todayConfig.close_hour);

  const nextSlot = needsNextDay
    ? findNextOpenSlot(workingHours, currentDay)
    : { config: todayConfig, dayDiff: 0 };

  if (!nextSlot) return { type: 'BACK_IN_SOME_TIME' };

  const { config, dayDiff } = nextSlot;
  const targetTime = toMinutes(
    config.open_all_day ? 0 : (config.open_hour ?? 0),
    config.open_minutes ?? 0
  );

  const { hours, minutes } = getTimeDifference(targetTime, currentTime);

  return formatTimeResponse({ dayDiff, hours, minutes, config, locale });
};
