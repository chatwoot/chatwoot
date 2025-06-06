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

const { t } = useI18n();

const DAY_NAMES = [
  t('DAY_NAMES.SUNDAY'),
  t('DAY_NAMES.MONDAY'),
  t('DAY_NAMES.TUESDAY'),
  t('DAY_NAMES.WEDNESDAY'),
  t('DAY_NAMES.THURSDAY'),
  t('DAY_NAMES.FRIDAY'),
  t('DAY_NAMES.SATURDAY'),
];

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
    hoursUntilOpen: Math.floor(slot.minutesUntilOpen / 60),
    remainingMinutes: slot.minutesUntilOpen % 60,
  };
});
</script>

<template>
  <span>
    <!-- Working hours disabled or all closed -->
    <template v-if="!workingHoursEnabled || allDayClosed">
      {{
        isOnline && !allDayClosed
          ? replyTimeMessage
          : t('TEAM_AVAILABILITY.BACK_AS_SOON_AS_POSSIBLE')
      }}
    </template>

    <!-- Currently online and in working hours -->
    <template v-else-if="isInWorkingHours && isOnline">
      {{ replyTimeMessage }}
    </template>

    <!-- Not available - need to calculate next slot -->
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
          day: DAY_NAMES[nextSlot.config.dayOfWeek],
        })
      }}
    </template>

    <!-- Same day - less than 1 hour (eg: in 5 minutes) -->
    <template v-else-if="nextSlot.hoursUntilOpen === 0">
      {{
        t('REPLY_TIME.BACK_IN_MINUTES', {
          time: `${Math.ceil(nextSlot.remainingMinutes / 5) * 5}`,
        })
      }}
    </template>

    <!-- Same day - less than 3 hours (eg: in 2 hours) -->
    <template v-else-if="nextSlot.hoursUntilOpen < 3">
      {{
        t('REPLY_TIME.BACK_IN_HOURS', {
          time:
            nextSlot.remainingMinutes > 0
              ? nextSlot.hoursUntilOpen + 1
              : nextSlot.hoursUntilOpen,
        })
      }}
    </template>

    <!-- Same day - 3+ hours away (eg: at 10:00 AM) -->
    <template v-else>
      {{
        t('REPLY_TIME.BACK_AT_TIME', {
          time: getTime(
            nextSlot.config.openHour || 0,
            nextSlot.config.openMinutes || 0
          ),
        })
      }}
    </template>
  </span>
</template>
