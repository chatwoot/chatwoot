<script setup>
import { computed, watch } from 'vue';
import Input from './Input.vue';
import { useI18n } from 'vue-i18n';
import { DURATION_UNITS } from './constants';

const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: Infinity },
  disabled: { type: Boolean, default: false },
});

const { t } = useI18n();
const duration = defineModel('modelValue', { type: Number, default: null });
const unit = defineModel('unit', {
  type: String,
  default: DURATION_UNITS.MINUTES,
  validate(value) {
    return Object.values(DURATION_UNITS).includes(value);
  },
});

const convertToMinutes = newValue => {
  if (unit.value === DURATION_UNITS.MINUTES) {
    return Math.floor(newValue);
  }
  if (unit.value === DURATION_UNITS.HOURS) {
    return Math.floor(newValue) * 60;
  }
  return Math.floor(newValue) * 24 * 60;
};

const transformedValue = computed({
  get() {
    if (unit.value === DURATION_UNITS.MINUTES) return duration.value;
    if (unit.value === DURATION_UNITS.HOURS)
      return Math.floor(duration.value / 60);
    if (unit.value === DURATION_UNITS.DAYS)
      return Math.floor(duration.value / 24 / 60);

    return 0;
  },
  set(newValue) {
    let minuteValue = convertToMinutes(newValue);

    duration.value = Math.min(Math.max(minuteValue, props.min), props.max);
  },
});

// when unit is changed set the nearest value to that unit
// so if the minute is set to 900, and the user changes the unit to "days"
// the transformed value will show 0, but the real value will still be 900
// this might create some confusion, especially when saving
// this watcher fixes it by rounding the duration basically, to the nearest unit value
watch(unit, () => {
  let adjustedValue = convertToMinutes(transformedValue.value);
  duration.value = Math.min(Math.max(adjustedValue, props.min), props.max);
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
    <option :value="DURATION_UNITS.MINUTES">
      {{ t('DURATION_INPUT.MINUTES') }}
    </option>
    <option :value="DURATION_UNITS.HOURS">
      {{ t('DURATION_INPUT.HOURS') }}
    </option>
    <option :value="DURATION_UNITS.DAYS">
      {{ t('DURATION_INPUT.DAYS') }}
    </option>
  </select>
</template>
