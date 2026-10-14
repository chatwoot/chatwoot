<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Select from 'dashboard/components-next/select/Select.vue';

defineProps({
  error: {
    type: String,
    default: '',
  },
  hoursAriaLabel: {
    type: String,
    required: true,
  },
  minutesAriaLabel: {
    type: String,
    required: true,
  },
});

const duration = defineModel({ type: Number, default: 60 });

const MINUTES_PER_HOUR = 60;
const STEP_MINUTES = 5;
const MIN_MINUTES = STEP_MINUTES;
const MAX_MINUTES = 24 * MINUTES_PER_HOUR;

const { t } = useI18n();

const clamp = (hours, minutes) => {
  duration.value = Math.min(
    Math.max(hours * MINUTES_PER_HOUR + minutes, MIN_MINUTES),
    MAX_MINUTES
  );
};

const hours = computed({
  get: () => Math.floor(duration.value / MINUTES_PER_HOUR),
  set: value => clamp(Number(value), duration.value % MINUTES_PER_HOUR),
});

const minutes = computed({
  get: () => duration.value % MINUTES_PER_HOUR,
  set: value => clamp(hours.value, Number(value)),
});

const hourOptions = computed(() =>
  Array.from({ length: MAX_MINUTES / MINUTES_PER_HOUR + 1 }, (_, value) => ({
    value,
    label: t(
      'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_HOURS_SHORT',
      { count: value }
    ),
  }))
);

const minuteOptions = computed(() =>
  Array.from({ length: MINUTES_PER_HOUR / STEP_MINUTES }, (_, index) => {
    const value = index * STEP_MINUTES;
    return {
      value,
      label: t(
        'CAPTAIN.ASSISTANTS.FORM.INACTIVITY_RESOLUTION.DURATION_MINUTES_SHORT',
        { count: value }
      ),
      disabled:
        (hours.value === 0 && value === 0) ||
        (hours.value === MAX_MINUTES / MINUTES_PER_HOUR && value !== 0),
    };
  })
);
</script>

<template>
  <div class="flex shrink-0 gap-2">
    <Select
      v-model="hours"
      :options="hourOptions"
      :error="error"
      :aria-label="hoursAriaLabel"
      class="[&>select]:min-w-24"
    />
    <Select
      v-model="minutes"
      :options="minuteOptions"
      :error="error"
      :aria-label="minutesAriaLabel"
      class="[&>select]:min-w-28"
    />
  </div>
</template>
