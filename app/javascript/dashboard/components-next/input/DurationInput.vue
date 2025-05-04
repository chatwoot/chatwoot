<script setup>
import { computed, ref } from 'vue';
import Input from './Input.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: Infinity },
  disabled: { type: Boolean, default: false },
});

const { t } = useI18n();
const duration = defineModel('modelValue', { type: Number, default: null });

const UNIT_TYPES = {
  MINUTES: 'minutes',
  HOURS: 'hours',
  DAYS: 'days',
};
const unit = ref(UNIT_TYPES.MINUTES);

const transformedValue = computed({
  get() {
    if (unit.value === UNIT_TYPES.MINUTES) return duration.value;
    if (unit.value === UNIT_TYPES.HOURS) return Math.floor(duration.value / 60);
    if (unit.value === UNIT_TYPES.DAYS)
      return Math.floor(duration.value / 24 / 60);

    return 0;
  },
  set(newValue) {
    let minuteValue;
    if (unit.value === UNIT_TYPES.MINUTES) {
      minuteValue = Math.floor(newValue);
    } else if (unit.value === UNIT_TYPES.HOURS) {
      minuteValue = Math.floor(newValue * 60);
    } else if (unit.value === UNIT_TYPES.DAYS) {
      minuteValue = Math.floor(newValue * 24 * 60);
    }

    duration.value = Math.min(Math.max(minuteValue, props.min), props.max);
  },
});
</script>

<template>
  <Input
    v-model="transformedValue"
    type="number"
    autocomplete="off"
    :disabled="disabled"
    :placeholder="t('DURATION_INPUT.PLACEHOLDER')"
    class="flex-grow w-full disabled:"
  />
  <select
    v-model="unit"
    :disabled="disabled"
    class="mb-0 text-sm disabled:outline-n-weak disabled:opacity-40"
  >
    <option :value="UNIT_TYPES.MINUTES">
      {{ t('DURATION_INPUT.MINUTES') }}
    </option>
    <option :value="UNIT_TYPES.HOURS">{{ t('DURATION_INPUT.HOURS') }}</option>
    <option :value="UNIT_TYPES.DAYS">{{ t('DURATION_INPUT.DAYS') }}</option>
  </select>
</template>
