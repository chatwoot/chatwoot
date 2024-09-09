import { ref, computed } from 'vue';
import {
  timeSlotParse,
  defaultTimeSlot,
} from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { utcToZonedTime } from 'date-fns-tz';
import { generateRelativeTime } from 'shared/helpers/DateHelper';
import { useI18n } from 'dashboard/composables/useI18n';

const MINUTE_ROUNDING_FACTOR = 5;

export const useNextAvailabilityTime = () => {
  const { t } = useI18n();
  const dayNames = t('DAY_NAMES');
  const timeSlots = ref([...defaultTimeSlot]);
  const timeSlot = ref({});

  const channelConfig = computed(() => window.chatwootWebChannel);
  const workingHours = computed(() => channelConfig.value.workingHours);
  const timeZoneValue = computed(() => channelConfig.value.timezone);
  const languageCode = computed(() => window.chatwootWebChannel.locale);

  const newDateWithTimeZone = computed(() =>
    utcToZonedTime(new Date(), timeZoneValue.value)
  );
  const presentHour = computed(() => newDateWithTimeZone.value.getHours());
  const presentMinute = computed(() => newDateWithTimeZone.value.getMinutes());

  const currentDay = computed(() => {
    const date = newDateWithTimeZone.value;
    const day = date.getDay();
    const getCurrentDay = Object.keys(dayNames).find(
      key => dayNames[key] === dayNames[day]
    );
    return Number(getCurrentDay);
  });

  const currentDayWorkingHours = computed(() =>
    workingHours.value.find(slot => slot.day_of_week === currentDay.value)
  );

  function getNextDay(day) {
    return (day + 1) % 7;
  }

  function getNextWorkingHour(day) {
    const workingHour = workingHours.value.find(
      slot => slot.day_of_week === day
    );
    if (workingHour && !workingHour.closed_all_day) {
      return workingHour;
    }
    return null;
  }

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
    return { openHour, openMinute, closeHour };
  });

  const nextDayTimings = computed(() => {
    const { open_hour: openHour, open_minutes: openMinute } =
      nextDayWorkingHours.value ?? {};
    return { openHour, openMinute };
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

  function setTimeSlot() {
    const workingTimeSlots = workingHours.value;

    const currentSlot =
      presentHour.value >= currentDayTimings.value.closeHour
        ? nextDayWorkingHours.value
        : currentDayWorkingHours.value;

    const slots = timeSlotParse(workingTimeSlots).length
      ? timeSlotParse(workingTimeSlots)
      : defaultTimeSlot;
    timeSlots.value = slots;

    timeSlot.value = timeSlots.value.find(
      slot => slot.day === currentSlot.day_of_week
    );
  }

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
    setTimeSlot,
  };
};
