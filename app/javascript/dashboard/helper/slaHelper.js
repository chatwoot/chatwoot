/**
 * Helper functions for SLA business hours configuration
 */

/**
 * Extracts business hours configuration from SLA policy and inbox data
 * Supports both camelCase and snake_case property naming conventions
 *
 * @param {Object} slaPolicy - The SLA policy object
 * @param {Object} inbox - The inbox object with working hours configuration
 * @returns {Object|null} Business hours configuration for utils package, or null if not applicable
 */
export const getBusinessHoursConfig = (slaPolicy, inbox) => {
  // Handle both camelCase and snake_case property names
  const onlyDuringBusinessHours =
    slaPolicy?.only_during_business_hours ?? slaPolicy?.onlyDuringBusinessHours;
  const workingHoursEnabled =
    inbox?.working_hours_enabled ?? inbox?.workingHoursEnabled;

  if (!onlyDuringBusinessHours || !workingHoursEnabled) {
    return null;
  }

  // Convert working hours format to match utils expectation
  const workingHours = {};
  const dayMap = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  // Handle both camelCase and snake_case working hours arrays
  const inboxWorkingHours = inbox.working_hours ?? inbox.workingHours;

  if (inboxWorkingHours) {
    inboxWorkingHours.forEach(dayConfig => {
      // Handle both property naming conventions
      const dayOfWeek = dayConfig.day_of_week ?? dayConfig.dayOfWeek;
      const closedAllDay = dayConfig.closed_all_day ?? dayConfig.closedAllDay;
      const openHour = dayConfig.open_hour ?? dayConfig.openHour;
      const openMinutes = dayConfig.open_minutes ?? dayConfig.openMinutes;
      const closeHour = dayConfig.close_hour ?? dayConfig.closeHour;
      const closeMinutes = dayConfig.close_minutes ?? dayConfig.closeMinutes;

      const dayName = dayMap[dayOfWeek];

      if (closedAllDay) {
        workingHours[dayName] = null;
      } else {
        // Convert to HH:MM format
        const startHour = String(openHour || 0).padStart(2, '0');
        const startMin = String(openMinutes || 0).padStart(2, '0');
        const endHour = String(closeHour || 0).padStart(2, '0');
        const endMin = String(closeMinutes || 0).padStart(2, '0');

        workingHours[dayName] = {
          start: `${startHour}:${startMin}`,
          finish: `${endHour}:${endMin}`,
        };
      }
    });
  }

  return {
    working_hours_enabled: workingHoursEnabled,
    timezone: inbox.timezone || 'UTC',
    working_hours: workingHours,
    only_during_business_hours: onlyDuringBusinessHours,
  };
};
