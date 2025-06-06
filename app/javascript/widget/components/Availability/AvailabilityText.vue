<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getTime } from 'dashboard/routes/dashboard/settings/inbox/helpers/businessHour.js';
import {
  isInWorkingHours,
  findNextAvailableSlotDetails,
  DAY_NAMES,
} from 'widget/helpers/availabilityHelpers';

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
});

const { t } = useI18n();

// Check if currently in working hours
const inWorkingHours = computed(() =>
  isInWorkingHours(props.time, props.utcOffset, props.workingHours)
);

// Check if all days are closed
const allClosed = computed(() => {
  if (!props.workingHours.length) return false;
  return props.workingHours.every(slot => slot.closed_all_day);
});

// Get reply time message
const replyTimeMessage = computed(() => {
  const replyTimeKey = `REPLY_TIME.${props.replyTime.toUpperCase()}`;
  return t(replyTimeKey);
});

// Calculate next available time message
const getNextAvailableMessage = () => {
  const nextSlot = findNextAvailableSlotDetails(
    props.time,
    props.utcOffset,
    props.workingHours
  );

  if (!nextSlot) {
    return t('REPLY_TIME.BACK_IN_SOME_TIME');
  }

  const { minutesUntilOpen, daysUntilOpen, config } = nextSlot;
  const hoursUntilOpen = Math.floor(minutesUntilOpen / 60);
  const remainingMinutes = minutesUntilOpen % 60;

  // Tomorrow
  if (daysUntilOpen === 1) {
    return t('REPLY_TIME.BACK_TOMORROW');
  }

  // Multiple days away
  if (daysUntilOpen > 1) {
    return t('REPLY_TIME.BACK_ON', { time: DAY_NAMES[config.day_of_week] });
  }

  // Same day - less than 3 hours
  if (hoursUntilOpen < 3) {
    // Only minutes
    if (hoursUntilOpen === 0) {
      const roundedMinutes = Math.ceil(remainingMinutes / 5) * 5;
      return t('REPLY_TIME.BACK_IN', { time: `${roundedMinutes} minutes` });
    }

    // Hours with minutes - round up
    if (remainingMinutes > 0) {
      return t('REPLY_TIME.BACK_IN', { time: `${hoursUntilOpen + 1} hours` });
    }

    // Exact hours
    return t('REPLY_TIME.BACK_IN', {
      time: `${hoursUntilOpen} ${hoursUntilOpen === 1 ? 'hour' : 'hours'}`,
    });
  }

  // Same day - 3+ hours away, show specific time
  const hour = config.open_hour || 0;
  const minute = config.open_minutes || 0;
  const formattedTime = getTime(hour, minute);
  return t('REPLY_TIME.BACK_AT', { time: formattedTime });
};

// Main availability text logic
const availabilityText = computed(() => {
  // Working hours disabled
  if (!props.workingHoursEnabled) {
    return props.isOnline
      ? replyTimeMessage.value
      : t('TEAM_AVAILABILITY.OFFLINE');
  }

  // All days closed
  if (allClosed.value) {
    return t('TEAM_AVAILABILITY.OFFLINE');
  }

  // Currently online and in working hours
  if (inWorkingHours.value && props.isOnline) {
    return replyTimeMessage.value;
  }

  // Calculate when we'll be back
  return getNextAvailableMessage();
});
</script>

<template>
  <span>{{ availabilityText }}</span>
</template>
