<script setup>
import { computed } from 'vue';
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
    let minuteValue;
    if (unit.value === DURATION_UNITS.MINUTES) {
      minuteValue = Math.floor(newValue);
    } else if (unit.value === DURATION_UNITS.HOURS) {
      minuteValue = Math.floor(newValue * 60);
    } else if (unit.value === DURATION_UNITS.DAYS) {
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
    <option :value="DURATION_UNITS.MINUTES">
      {{ t('DURATION_INPUT.MINUTES') }}
    </option>
    <option :value="DURATION_UNITS.HOURS">
      {{ t('DURATION_INPUT.HOURS') }}
    </option>
    <option :value="DURATION_UNITS.DAYS">{{ t('DURATION_INPUT.DAYS') }}</option>
  </select>
</template>
