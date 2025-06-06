import { utcToZonedTime } from 'date-fns-tz';

// Constants
const DAYS_IN_WEEK = 7;
const MINUTES_IN_HOUR = 60;
const MINUTES_IN_DAY = 24 * 60;

/**
 * Get date in timezone
 * @param {Date|string} time
 * @param {string} utcOffset
 * @returns {Date}
 */
const getDateInTimezone = (time, utcOffset) => {
  const dateString = time instanceof Date ? time.toISOString() : time;
  return utcToZonedTime(dateString, utcOffset);
};

/**
 * Convert time to minutes
 * @param {number} hours
 * @param {number} minutes
 * @returns {number}
 */
const toMinutes = (hours = 0, minutes = 0) => hours * MINUTES_IN_HOUR + minutes;

/**
 * Get today's config
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

  if (todayConfig.openAllDay) return true;
  if (todayConfig.closedAllDay) return false;

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

  // Handle normal case
  if (closeMinutes > openMinutes) {
    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  // Handle midnight crossing
  return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
};

/**
 * Find next available slot with detailed information
 * @param {Date|string} time
 * @param {string} utcOffset
 * @param {Array} workingHours
 * @returns {Object|null}
 */
export const findNextAvailableSlotDetails = (time, utcOffset, workingHours) => {
  const date = getDateInTimezone(time, utcOffset);
  const currentDay = date.getDay();
  const currentHour = date.getHours();
  const currentMinutes = toMinutes(currentHour, date.getMinutes());

  // Create map of open days for quick lookup
  const openDays = new Map(
    workingHours
      .filter(slot => !slot.closedAllDay)
      .map(slot => [slot.dayOfWeek, slot])
  );

  // No open days at all
  if (openDays.size === 0) return null;

  // Check today first
  const todayConfig = openDays.get(currentDay);
  if (todayConfig && !todayConfig.openAllDay) {
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
  }

  const nextSlot = Array.from({ length: DAYS_IN_WEEK }, (_, i) => i + 1)
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
        currentMinutes + // Rest of today
        (daysAhead - 1) * MINUTES_IN_DAY + // Full days in between
        slotOpenMinutes; // Time until opening on target day

      return {
        config,
        minutesUntilOpen,
        daysUntilOpen: daysAhead,
        dayOfWeek: targetDay,
      };
    })
    .find(slot => slot !== null);

  return nextSlot || null;
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
