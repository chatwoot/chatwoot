import { utcToZonedTime } from 'date-fns-tz';

// Constants
const DAYS_IN_WEEK = 7;
const MINUTES_IN_HOUR = 60;
const MINUTES_IN_DAY = 24 * 60;

// ---------------------------------------------------------------------------
// Internal helper utilities
// ---------------------------------------------------------------------------

/**
 * Get date in timezone
 * @private
 * @param {Date|string} time
 * @param {string} utcOffset
 * @returns {Date}
 */
const getDateInTimezone = (time, utcOffset) => {
  const dateString = time instanceof Date ? time.toISOString() : time;
  try {
    return utcToZonedTime(dateString, utcOffset);
  } catch (error) {
    const userTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    // eslint-disable-next-line no-console
    console.warn(
      `Invalid timezone: ${utcOffset}, falling back to user timezone: ${userTimezone}`
    );
    return utcToZonedTime(dateString, userTimezone);
  }
};

/**
 * Convert time to minutes
 * @private
 * @param {number} hours
 * @param {number} minutes
 * @returns {number}
 */
const toMinutes = (hours = 0, minutes = 0) => hours * MINUTES_IN_HOUR + minutes;

/**
 * Get today's config
 * @private
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {Object|null}
 */
const getTodayConfig = (time, utcOffset, workingHours) => {
  const date = getDateInTimezone(time, utcOffset);
  const dayOfWeek = date.getDay();
  return workingHours.find(slot => slot.dayOfWeek === dayOfWeek) || null;
};

/**
 * Check if current time is within working range, handling midnight crossing
 * @private
 * @param {number} currentMinutes
 * @param {number} openMinutes
 * @param {number} closeMinutes
 * @returns {boolean}
 */
const isTimeWithinRange = (currentMinutes, openMinutes, closeMinutes) => {
  const crossesMidnight = closeMinutes <= openMinutes;

  return crossesMidnight
    ? currentMinutes >= openMinutes || currentMinutes < closeMinutes
    : currentMinutes >= openMinutes && currentMinutes < closeMinutes;
};

/**
 * Build a map keyed by `dayOfWeek` for all slots that are NOT closed all day.
 * @private
 *
 * @param {Array<Object>} workingHours - Full array of working-hour slot configs.
 * @returns {Map<number, Object>} Map where the key is the numeric day (0-6) and the value is the slot config.
 */
const getOpenDaysMap = workingHours =>
  new Map(
    (workingHours || [])
      .filter(slot => !slot.closedAllDay)
      .map(slot => [slot.dayOfWeek, slot])
  );

/**
 * Determine if today's slot is still upcoming.
 * @private
 * Returns an object with details if the slot is yet to open, otherwise `null`.
 *
 * @param {number} currentDay - `Date#getDay()` value (0-6) for current time.
 * @param {number} currentMinutes - Minutes since midnight for current time.
 * @param {Map<number, Object>} openDays - Map produced by `getOpenDaysMap`.
 * @returns {Object|null} Slot details (config, minutesUntilOpen, etc.) or `null`.
 */
const checkTodayAvailability = (currentDay, currentMinutes, openDays) => {
  const todayConfig = openDays.get(currentDay);
  if (!todayConfig || todayConfig.openAllDay) return null;

  const todayOpenMinutes = toMinutes(
    todayConfig.openHour ?? 0,
    todayConfig.openMinutes ?? 0
  );

  // Haven't opened yet today
  if (currentMinutes < todayOpenMinutes) {
    return {
      config: todayConfig,
      minutesUntilOpen: todayOpenMinutes - currentMinutes,
      daysUntilOpen: 0,
      dayOfWeek: currentDay,
    };
  }
  return null;
};

/**
 * Search the upcoming days (including tomorrow) for the next open slot.
 * @private
 *
 * @param {number} currentDay - Day index (0-6) representing today.
 * @param {number} currentMinutes - Minutes since midnight for current time.
 * @param {Map<number, Object>} openDays - Map of open day configs.
 * @returns {Object|null} Details of the next slot or `null` if none found.
 */
const findNextSlot = (currentDay, currentMinutes, openDays) =>
  Array.from({ length: DAYS_IN_WEEK }, (_, i) => i + 1)
    .map(daysAhead => {
      const targetDay = (currentDay + daysAhead) % DAYS_IN_WEEK;
      const config = openDays.get(targetDay);

      if (!config) return null;

      // Calculate minutes until this slot opens
      const slotOpenMinutes = config.openAllDay
        ? 0
        : toMinutes(config.openHour ?? 0, config.openMinutes ?? 0);
      const minutesUntilOpen =
        MINUTES_IN_DAY -
        currentMinutes + // remaining mins today
        (daysAhead - 1) * MINUTES_IN_DAY + // full days between
        slotOpenMinutes; // opening on target day

      return {
        config,
        minutesUntilOpen,
        daysUntilOpen: daysAhead,
        dayOfWeek: targetDay,
      };
    })
    .find(Boolean) || null;

/**
 * Convert slot details from inbox timezone to user timezone
 * @private
 * @param {Date} time - Current time
 * @param {string} inboxTz - Inbox timezone
 * @param {Object} slotDetails - Original slot details
 * @returns {Object} Slot details with user timezone adjustments
 */
const convertSlotToUserTimezone = (time, inboxTz, slotDetails) => {
  if (!slotDetails) return null;

  const userTz = Intl.DateTimeFormat().resolvedOptions().timeZone;

  // If timezones match, no conversion needed
  if (inboxTz === userTz) return slotDetails;

  // Calculate when the slot opens (absolute time)
  const now = time instanceof Date ? time : new Date(time);
  const openingTime = new Date(
    now.getTime() + slotDetails.minutesUntilOpen * 60000
  );

  // Convert to user timezone
  const openingInUserTz = getDateInTimezone(openingTime, userTz);
  const nowInUserTz = getDateInTimezone(now, userTz);

  // Calculate days difference in user timezone
  const openingDate = new Date(openingInUserTz);
  openingDate.setHours(0, 0, 0, 0);
  const todayDate = new Date(nowInUserTz);
  todayDate.setHours(0, 0, 0, 0);
  const daysUntilOpen = Math.round((openingDate - todayDate) / 86400000);

  // Return with user timezone adjustments
  return {
    ...slotDetails,
    config: {
      ...slotDetails.config,
      openHour: openingInUserTz.getHours(),
      openMinutes: openingInUserTz.getMinutes(),
      dayOfWeek: openingInUserTz.getDay(),
    },
    daysUntilOpen,
    dayOfWeek: openingInUserTz.getDay(),
  };
};

// ---------------------------------------------------------------------------
// Exported functions
// ---------------------------------------------------------------------------

/**
 * Check if open all day
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {boolean}
 */
export const isOpenAllDay = (time, utcOffset, workingHours = []) => {
  const todayConfig = getTodayConfig(time, utcOffset, workingHours);
  return todayConfig?.openAllDay === true;
};

/**
 * Check if closed all day
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {boolean}
 */
export const isClosedAllDay = (time, utcOffset, workingHours = []) => {
  const todayConfig = getTodayConfig(time, utcOffset, workingHours);
  return todayConfig?.closedAllDay === true;
};

/**
 * Check if in working hours
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {boolean}
 */
export const isInWorkingHours = (time, utcOffset, workingHours = []) => {
  if (!workingHours.length) return false;

  const todayConfig = getTodayConfig(time, utcOffset, workingHours);
  if (!todayConfig) return false;

  // Handle all-day states
  if (todayConfig.openAllDay) return true;
  if (todayConfig.closedAllDay) return false;

  // Check time-based availability
  const date = getDateInTimezone(time, utcOffset);
  const currentMinutes = toMinutes(date.getHours(), date.getMinutes());

  const openMinutes = toMinutes(
    todayConfig.openHour ?? 0,
    todayConfig.openMinutes ?? 0
  );
  const closeMinutes = toMinutes(
    todayConfig.closeHour ?? 0,
    todayConfig.closeMinutes ?? 0
  );

  return isTimeWithinRange(currentMinutes, openMinutes, closeMinutes);
};

/**
 * Find next available slot with detailed information
 * Returns times adjusted to user's timezone for display
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {Object|null}
 */
export const findNextAvailableSlotDetails = (
  time,
  utcOffset,
  workingHours = []
) => {
  const date = getDateInTimezone(time, utcOffset);
  const currentDay = date.getDay();
  const currentMinutes = toMinutes(date.getHours(), date.getMinutes());

  const openDays = getOpenDaysMap(workingHours);

  // No open days at all
  if (openDays.size === 0) return null;

  // Check today first
  const todaySlot = checkTodayAvailability(
    currentDay,
    currentMinutes,
    openDays
  );

  // Find the slot (today or next)
  const slotDetails =
    todaySlot || findNextSlot(currentDay, currentMinutes, openDays);

  // Convert to user timezone for display
  return convertSlotToUserTimezone(time, utcOffset, slotDetails);
};

/**
 * Find minutes until next available slot
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {number|null}
 */
export const findNextAvailableSlotDiff = (
  time,
  utcOffset,
  workingHours = []
) => {
  if (isInWorkingHours(time, utcOffset, workingHours)) {
    return 0;
  }

  const nextSlot = findNextAvailableSlotDetails(time, utcOffset, workingHours);
  return nextSlot ? nextSlot.minutesUntilOpen : null;
};

/**
 * Check if online
 * @param {boolean} workingHoursEnabled
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @param {boolean} hasOnlineAgents
 * @returns {boolean}
 */
export const isOnline = (
  workingHoursEnabled,
  time,
  utcOffset,
  workingHours,
  hasOnlineAgents
) => {
  if (!workingHoursEnabled) {
    return hasOnlineAgents;
  }

  const inWorkingHours = isInWorkingHours(time, utcOffset, workingHours);
  return inWorkingHours && hasOnlineAgents;
};
