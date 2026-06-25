<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getTime } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import { findNextAvailableSlotDetails } from 'widget/helpers/availabilityHelpers';

const props = defineProps({
  time: {
    type: Date,
    required: true,
  },
  utcOffset: {
    type: String,
    required: true,
  },
  workingHours: {
    type: Array,
    required: true,
  },
  workingHoursEnabled: {
    type: Boolean,
    required: true,
  },
  replyTime: {
    type: String,
    default: 'in_a_few_minutes',
  },
  isOnline: {
    type: Boolean,
    required: true,
  },
  isInWorkingHours: {
    type: Boolean,
    required: true,
  },
});

const MINUTE_ROUNDING_INTERVAL = 5;
const HOUR_THRESHOLD_FOR_EXACT_TIME = 3;
const MINUTES_IN_HOUR = 60;

const { t } = useI18n();

const dayNames = computed(() => [
  t('DAY_NAMES.SUNDAY'),
  t('DAY_NAMES.MONDAY'),
  t('DAY_NAMES.TUESDAY'),
  t('DAY_NAMES.WEDNESDAY'),
  t('DAY_NAMES.THURSDAY'),
  t('DAY_NAMES.FRIDAY'),
  t('DAY_NAMES.SATURDAY'),
]);

// Check if all days in working hours are closed
const allDayClosed = computed(() => {
  if (!props.workingHours.length) return false;
  return props.workingHours.every(slot => slot.closedAllDay);
});

const replyTimeMessage = computed(() => {
  const replyTimeKey = `REPLY_TIME.${props.replyTime.toUpperCase()}`;
  return t(replyTimeKey);
});

const nextSlot = computed(() => {
  if (
    !props.workingHoursEnabled ||
    allDayClosed.value ||
    (props.isInWorkingHours && props.isOnline)
  ) {
    return null;
  }

  const slot = findNextAvailableSlotDetails(
    props.time,
    props.utcOffset,
    props.workingHours
  );
  if (!slot) return null;

  return {
    ...slot,
    hoursUntilOpen: Math.floor(slot.minutesUntilOpen / MINUTES_IN_HOUR),
    remainingMinutes: slot.minutesUntilOpen % MINUTES_IN_HOUR,
  };
});

const roundedMinutesUntilOpen = computed(() => {
  if (!nextSlot.value) return 0;
  return (
    Math.ceil(nextSlot.value.remainingMinutes / MINUTE_ROUNDING_INTERVAL) *
    MINUTE_ROUNDING_INTERVAL
  );
});

const adjustedHoursUntilOpen = computed(() => {
  if (!nextSlot.value) return 0;
  return nextSlot.value.remainingMinutes > 0
    ? nextSlot.value.hoursUntilOpen + 1
    : nextSlot.value.hoursUntilOpen;
});

const formattedOpeningTime = computed(() => {
  if (!nextSlot.value) return '';
  return getTime(
    nextSlot.value.config.openHour || 0,
    nextSlot.value.config.openMinutes || 0
  );
});
</script>

<template>
  <span>
    <!-- 1. If currently in working hours, show reply time -->
    <template v-if="isInWorkingHours">
      {{ replyTimeMessage }}
    </template>

    <!-- 2. Else, if working hours are disabled, show based on online status -->
    <template v-else-if="!workingHoursEnabled">
      {{
        isOnline
          ? replyTimeMessage
          : t('TEAM_AVAILABILITY.BACK_AS_SOON_AS_POSSIBLE')
      }}
    </template>

    <!-- 3. Else (not in working hours, but working hours ARE enabled) -->
    <!-- Check if all configured slots are 'closedAllDay' -->
    <template v-else-if="allDayClosed">
      {{ t('TEAM_AVAILABILITY.BACK_AS_SOON_AS_POSSIBLE') }}
    </template>

    <!-- 4. Else (not in WH, WH enabled, not allDayClosed), calculate next slot -->
    <template v-else-if="!nextSlot">
      {{ t('REPLY_TIME.BACK_IN_SOME_TIME') }}
    </template>

    <!-- Tomorrow -->
    <template v-else-if="nextSlot.daysUntilOpen === 1">
      {{ t('REPLY_TIME.BACK_TOMORROW') }}
    </template>

    <!-- Multiple days away (eg: on Monday) -->
    <template v-else-if="nextSlot.daysUntilOpen > 1">
      {{
        t('REPLY_TIME.BACK_ON_DAY', {
          day: dayNames[nextSlot.config.dayOfWeek],
        })
      }}
    </template>

    <!-- Same day - less than 1 hour (eg: in 5 minutes) -->
    <template v-else-if="nextSlot.hoursUntilOpen === 0">
      {{
        t('REPLY_TIME.BACK_IN_MINUTES', {
          time: `${roundedMinutesUntilOpen}`,
        })
      }}
    </template>

    <!-- Same day - less than 3 hours (eg: in 2 hours) -->
    <template
      v-else-if="nextSlot.hoursUntilOpen < HOUR_THRESHOLD_FOR_EXACT_TIME"
    >
      {{ t('REPLY_TIME.BACK_IN_HOURS', adjustedHoursUntilOpen) }}
    </template>

    <!-- Same day - 3+ hours away (eg: at 10:00 AM) -->
    <template v-else>
      {{
        t('REPLY_TIME.BACK_AT_TIME', {
          time: formattedOpeningTime,
        })
      }}
    </template>
  </span>
</template>
