import { ref, computed } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import {
  timeSlotParse,
  defaultTimeSlot,
} from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { utcToZonedTime } from 'date-fns-tz';
import { generateRelativeTime } from 'shared/helpers/DateHelper';

const MINUTE_ROUNDING_FACTOR = 5;

/**
 * Composable for handling next availability calculations
 * @returns {Object} An object containing computed properties and methods for next availability management
 */
export function useNextAvailability() {
  const { t } = useI18n();
  const dayNames = t('DAY_NAMES');
  const timeSlots = ref([...defaultTimeSlot]);
  const timeSlot = ref({});

  const channelConfig = computed(() => window.chatwootWebChannel);
  const workingHours = computed(() => channelConfig.value.workingHours);
  const newDateWithTimeZone = computed(() =>
    utcToZonedTime(new Date(), timeZoneValue.value)
  );
  const presentHour = computed(() => newDateWithTimeZone.value.getHours());
  const presentMinute = computed(() => newDateWithTimeZone.value.getMinutes());
  const currentDay = computed(() => {
    const date = newDateWithTimeZone.value;
    const day = date.getDay();
    const currentDay = Object.keys(dayNames).find(
      key => dayNames[key] === dayNames[day]
    );
    return Number(currentDay);
  });
  const timeZoneValue = computed(() => channelConfig.value.timezone);
  const languageCode = computed(() => window.chatwootWebChannel.locale);

  const currentDayWorkingHours = computed(() =>
    workingHours.value.find(slot => slot.day_of_week === currentDay.value)
  );

  const nextDayWorkingHours = computed(() => {
    let nextDay = getNextDay(currentDay.value);
    let nextWorkingHour = getNextWorkingHour(nextDay);

    while (!nextWorkingHour) {
      nextDay = getNextDay(nextDay);
      nextWorkingHour = getNextWorkingHour(nextDay);
    }
    return nextWorkingHour;
  });

  const currentDayTimings = computed(() => {
    const {
      open_hour: openHour,
      open_minutes: openMinute,
      close_hour: closeHour,
    } = currentDayWorkingHours.value ?? {};
    return {
      openHour,
      openMinute,
      closeHour,
    };
  });

  const nextDayTimings = computed(() => {
    const { open_hour: openHour, open_minutes: openMinute } =
      nextDayWorkingHours.value ?? {};
    return {
      openHour,
      openMinute,
    };
  });

  const dayDiff = computed(() => {
    const nextDay = nextDayWorkingHours.value.day_of_week;
    const totalDays = 6;
    return nextDay > currentDay.value
      ? nextDay - currentDay.value - 1
      : totalDays - currentDay.value + nextDay;
  });

  const dayNameOfNextWorkingDay = computed(
    () => dayNames[nextDayWorkingHours.value.day_of_week]
  );

  const hoursAndMinutesBackInOnline = computed(() => {
    if (presentHour.value >= currentDayTimings.value.closeHour) {
      return getHoursAndMinutesUntilNextDayOpen(
        nextDayWorkingHours.value.open_all_day
          ? 0
          : nextDayTimings.value.openHour,
        nextDayTimings.value.openMinute,
        currentDayTimings.value.closeHour
      );
    }
    return getHoursAndMinutesUntilNextDayOpen(
      currentDayTimings.value.openHour,
      currentDayTimings.value.openMinute,
      currentDayTimings.value.closeHour
    );
  });

  const exactTimeInAmPm = computed(
    () =>
      `${
        timeSlot.value.day === currentDay.value
          ? `at ${timeSlot.value.from}`
          : ''
      }`
  );

  const hoursAndMinutesLeft = computed(() => {
    const { hoursLeft, minutesLeft } = hoursAndMinutesBackInOnline.value;

    const timeLeftChars = [];

    if (hoursLeft > 0) {
      const roundedUpHoursLeft = minutesLeft > 0 ? hoursLeft + 1 : hoursLeft;
      const hourRelative = generateRelativeTime(
        roundedUpHoursLeft,
        'hour',
        languageCode.value
      );
      timeLeftChars.push(`${hourRelative}`);
    }

    if (minutesLeft > 0 && hoursLeft === 0) {
      const roundedUpMinLeft =
        Math.ceil(minutesLeft / MINUTE_ROUNDING_FACTOR) *
        MINUTE_ROUNDING_FACTOR;
      const minRelative = generateRelativeTime(
        roundedUpMinLeft,
        'minutes',
        languageCode.value
      );
      timeLeftChars.push(`${minRelative}`);
    }

    return timeLeftChars.join(' ');
  });

  const hoursAndMinutesToBack = computed(() => {
    const { hoursLeft, minutesLeft } = hoursAndMinutesBackInOnline.value;
    if (hoursLeft >= 3) {
      return exactTimeInAmPm.value;
    }
    if (hoursLeft > 0 || minutesLeft > 0) {
      return hoursAndMinutesLeft.value;
    }
    return 'in some time';
  });

  const timeLeftToBackInOnline = computed(() => {
    if (
      hoursAndMinutesBackInOnline.value.hoursLeft >= 24 ||
      (timeSlot.value.day !== currentDay.value && dayDiff.value === 0)
    ) {
      const hourRelative = generateRelativeTime(
        dayDiff.value + 1,
        'days',
        languageCode.value
      );
      return `${hourRelative}`;
    }
    if (
      dayDiff.value >= 1 &&
      presentHour.value >= currentDayTimings.value.closeHour
    ) {
      return `on ${dayNameOfNextWorkingDay.value}`;
    }
    return hoursAndMinutesToBack.value;
  });

  /**
   * Gets the next day of the week
   * @param {number} day - Current day of the week
   * @returns {number} Next day of the week
   */
  function getNextDay(day) {
    return (day + 1) % 7;
  }

  /**
   * Gets the next working hour for a given day
   * @param {number} day - Day of the week
   * @returns {Object|null} Working hour object for the next working day, or null if not found
   */
  function getNextWorkingHour(day) {
    const workingHour = workingHours.value.find(
      slot => slot.day_of_week === day
    );
    if (workingHour && !workingHour.closed_all_day) {
      return workingHour;
    }
    return null;
  }

  /**
   * Calculates hours and minutes until next day open
   * @param {number} openHour - Opening hour
   * @param {number} openMinutes - Opening minutes
   * @param {number} closeHour - Closing hour
   * @returns {Object} Object containing hours and minutes left
   */
  function getHoursAndMinutesUntilNextDayOpen(
    openHour,
    openMinutes,
    closeHour
  ) {
    if (closeHour < openHour) {
      openHour += 24;
    }
    let diffMinutes =
      openHour * 60 +
      openMinutes -
      (presentHour.value * 60 + presentMinute.value);
    diffMinutes = diffMinutes < 0 ? diffMinutes + 24 * 60 : diffMinutes;
    const [hoursLeft, minutesLeft] = [
      Math.floor(diffMinutes / 60),
      diffMinutes % 60,
    ];

    return { hoursLeft, minutesLeft };
  }

  /**
   * Sets the time slot
   */
  function setTimeSlot() {
    const timeSlots = workingHours.value;

    const currentSlot =
      presentHour.value >= currentDayTimings.value.closeHour
        ? nextDayWorkingHours.value
        : currentDayWorkingHours.value;

    const slots = timeSlotParse(timeSlots).length
      ? timeSlotParse(timeSlots)
      : defaultTimeSlot;
    timeSlots.value = slots;

    timeSlot.value = timeSlots.value.find(
      slot => slot.day === currentSlot.day_of_week
    );
  }

  // Call setTimeSlot initially
  setTimeSlot();

  return {
    dayNames,
    timeSlots,
    timeSlot,
    channelConfig,
    workingHours,
    newDateWithTimeZone,
    presentHour,
    presentMinute,
    currentDay,
    timeZoneValue,
    languageCode,
    currentDayWorkingHours,
    nextDayWorkingHours,
    currentDayTimings,
    nextDayTimings,
    dayDiff,
    dayNameOfNextWorkingDay,
    hoursAndMinutesBackInOnline,
    exactTimeInAmPm,
    hoursAndMinutesLeft,
    hoursAndMinutesToBack,
    timeLeftToBackInOnline,
    getNextDay,
    getNextWorkingHour,
    getHoursAndMinutesUntilNextDayOpen,
    setTimeSlot,
  };
}
