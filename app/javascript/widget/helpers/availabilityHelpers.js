import { getTime } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { utcToZonedTime } from 'date-fns-tz';
import { generateRelativeTime } from 'shared/helpers/DateHelper';

const DAYS_IN_WEEK = 7;
const HOURS_IN_DAY = 24;
const MINUTES_IN_HOUR = 60;
const THREE_HOURS = 3;
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
  const openSlotsByDay = workingHours.reduce((acc, slot) => {
    if (!slot.closed_all_day) {
      acc[slot.day_of_week] = slot;
    }
    return acc;
  }, {});

  // Check next 7 days
  for (let i = 1; i <= DAYS_IN_WEEK; i += 1) {
    const day = (currentDay + i) % DAYS_IN_WEEK;
    const slot = openSlotsByDay[day];
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

// Response type builders
const backInResponse = value => ({ type: 'BACK_IN', value });
const backInSomeTimeResponse = () => ({ type: 'BACK_IN_SOME_TIME' });

// Get specific time response (eg: at 09:00 AM)
const getSpecificTimeResponse = config => {
  const targetHour = config.open_all_day ? 0 : (config.open_hour ?? 0);
  const targetMinute = config.open_minutes ?? 0;
  return { type: 'BACK_AT', value: getTime(targetHour, targetMinute) };
};

// Get relative hours response (eg: in 2 hours)
const getRelativeHoursResponse = (hours, minutes, locale) => {
  const roundedHours = minutes > 0 ? hours + 1 : hours;
  return backInResponse(generateRelativeTime(roundedHours, 'hour', locale));
};

// Get relative minutes response (eg: in 15 minutes)
const getRelativeMinutesResponse = (minutes, locale) => {
  const roundedMinutes = Math.ceil(minutes / 5) * 5;
  return backInResponse(
    generateRelativeTime(roundedMinutes, 'minutes', locale)
  );
};

// Get response for multiple days (eg: tomorrow, on Friday)
const getMultipleDayResponse = (dayDiff, hours, config) => {
  if (dayDiff === 1) return { type: 'BACK_TOMORROW' };
  if (dayDiff > 1 || hours >= HOURS_IN_DAY) {
    return { type: 'BACK_ON', value: DAY_NAMES[config.day_of_week] };
  }
  return null;
};

// Get same day response (eg: in 2 hours, in 15 minutes, at 09:00 AM)
const getSameDayResponse = (hours, minutes, config, locale) => {
  if (hours >= THREE_HOURS) return getSpecificTimeResponse(config);
  if (hours > 0) return getRelativeHoursResponse(hours, minutes, locale);
  if (minutes > 0) return getRelativeMinutesResponse(minutes, locale);
  return null;
};

// Format response based on time difference
const formatTimeResponse = ({ dayDiff, hours, minutes, config, locale }) => {
  const multipleDayResponse = getMultipleDayResponse(dayDiff, hours, config);
  if (multipleDayResponse) return multipleDayResponse; // eg: tomorrow, on Friday

  const sameDayResponse = getSameDayResponse(hours, minutes, config, locale);
  return sameDayResponse || backInSomeTimeResponse(); // eg: in 2 hours, in 15 minutes, at 09:00 AM
};

// Get target configuration
const getTargetConfig = (
  todayConfig,
  workingHours,
  currentDay,
  currentHour
) => {
  const needsNextDay =
    todayConfig.closed_all_day ||
    (todayConfig.close_hour && currentHour >= todayConfig.close_hour) ||
    (todayConfig.open_hour === 0 && currentHour > 0); // Special case: if working hours start at midnight and we're past midnight, we need to go to next occurrence of this day

  if (!needsNextDay) return { config: todayConfig, dayDiff: 0 };

  return findNextOpenSlot(workingHours, currentDay) || null;
};

// Calculate next available time details
const calculateNextAvailable = (workingHoursInfo, locale) => {
  const { currentDay, currentHour, currentMinute, todayConfig, workingHours } =
    workingHoursInfo;
  const currentTime = toMinutes(currentHour, currentMinute);

  const targetConfig = getTargetConfig(
    todayConfig,
    workingHours,
    currentDay,
    currentHour
  );
  if (!targetConfig) return null;

  const { config, dayDiff } = targetConfig;
  const targetTime = toMinutes(
    config.open_all_day ? 0 : (config.open_hour ?? 0),
    config.open_minutes ?? 0
  );

  const { hours, minutes } = getTimeDifference(targetTime, currentTime);

  return formatTimeResponse({ dayDiff, hours, minutes, config, locale });
};

// Get next available time
export const getNextAvailableTime = (workingHoursInfo, locale) => {
  if (!workingHoursInfo.workingHours?.length) return backInSomeTimeResponse();

  const result = calculateNextAvailable(workingHoursInfo, locale);
  return result || backInSomeTimeResponse();
};
