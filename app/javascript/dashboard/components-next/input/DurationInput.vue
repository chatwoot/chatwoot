<script setup>
import { computed, watch } from 'vue';
import Input from './Input.vue';
import { useI18n } from 'vue-i18n';
import { DURATION_UNITS, MINUTES_PER_UNIT } from './constants';

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

const minutesPerUnit = computed(() => MINUTES_PER_UNIT[unit.value]);

// The input only ever shows whole units, so the duration has to be a whole number of them too --
// otherwise the field displays one value (floored) while a different one is saved. `min` is in
// minutes, so express it in the selected unit and round up: 10 minutes is at least one day.
const toWholeUnits = unitValue => {
  const floor = Math.ceil(props.min / minutesPerUnit.value);
  const ceiling = Math.floor(props.max / minutesPerUnit.value);
  return Math.min(Math.max(Math.floor(unitValue), floor), ceiling);
};

const transformedValue = computed({
  get() {
    if (duration.value == null) return null;

    return Math.floor(duration.value / minutesPerUnit.value);
  },
  set(newValue) {
    if (newValue == null || newValue === '') {
      duration.value = null;
      return;
    }

    duration.value = toWholeUnits(newValue) * minutesPerUnit.value;
  },
});

// Switching units re-expresses the same duration rather than truncating it: 4 hours becomes 1 day,
// not 0 days silently clamped back to `min` minutes.
watch(unit, () => {
  if (duration.value == null) return;

  // At least one whole unit: rounding 4 hours down to 0 days would throw the duration away.
  const rounded = Math.max(
    Math.round(duration.value / minutesPerUnit.value),
    1
  );
  duration.value = toWholeUnits(rounded) * minutesPerUnit.value;
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
