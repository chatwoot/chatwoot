<script setup>
import { computed, ref, watch } from 'vue';
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

// Which bound a picked unit ran into, so the adjustment is said next to the field.
const adjustedTo = ref(null);

const transformedValue = computed({
  get() {
    if (duration.value == null) return null;
    if (unit.value === DURATION_UNITS.MINUTES) return duration.value;
    if (unit.value === DURATION_UNITS.HOURS)
      return Math.floor(duration.value / 60);
    if (unit.value === DURATION_UNITS.DAYS)
      return Math.floor(duration.value / 24 / 60);

    return 0;
  },
  set(newValue) {
    adjustedTo.value = null;
    if (newValue == null || newValue === '') {
      duration.value = null;
      return;
    }
    duration.value = convertToMinutes(newValue);
  },
});

const normalizeDuration = () => {
  if (duration.value == null) return;

  duration.value = Math.min(Math.max(duration.value, props.min), props.max);
};

// A unit the user picks keeps the number on screen: "2" hours becomes "2" days. Converting the
// duration instead reads as 0 days and then snaps to the minimum, so the field shows a number
// nobody typed. When the kept number falls outside the range it is brought to the bound, since not
// every form validates the range before saving, and the field says so instead of passing the bound
// off as what the user typed.
let countToKeep = null;
const onUnitSelected = event => {
  countToKeep = transformedValue.value;
  unit.value = event.target.value;
};

// A unit set by the parent (to show a saved value in its largest whole unit) keeps the duration
// and rounds it to the new unit, so if the minute is set to 900 and the unit becomes "days" the
// field does not show 0 while 900 is what gets saved.
watch(unit, () => {
  const keptCount = countToKeep;
  countToKeep = null;
  adjustedTo.value = null;
  if (duration.value == null) return;
  if (keptCount != null) {
    const kept = convertToMinutes(keptCount);
    duration.value = Math.min(Math.max(kept, props.min), props.max);
    if (kept > props.max) adjustedTo.value = 'MAX';
    else if (kept < props.min) adjustedTo.value = 'MIN';
    return;
  }
  let adjustedValue = convertToMinutes(transformedValue.value);
  duration.value = Math.min(Math.max(adjustedValue, props.min), props.max);
});
const unitLabels = computed(() => ({
  [DURATION_UNITS.MINUTES]: t('DURATION_INPUT.MINUTES'),
  [DURATION_UNITS.HOURS]: t('DURATION_INPUT.HOURS'),
  [DURATION_UNITS.DAYS]: t('DURATION_INPUT.DAYS'),
}));

const adjustedMessage = computed(() => {
  if (!adjustedTo.value) return '';
  return t(`DURATION_INPUT.ADJUSTED_TO_${adjustedTo.value}`, {
    value: transformedValue.value,
    unit: unitLabels.value[unit.value].toLowerCase(),
  });
});
</script>

<template>
  <Input
    v-model="transformedValue"
    type="number"
    autocomplete="off"
    :disabled="disabled"
    :placeholder="t('DURATION_INPUT.PLACEHOLDER')"
    :message="adjustedMessage"
    class="flex-grow w-full disabled:"
    @blur="normalizeDuration"
    @keydown.enter="normalizeDuration"
  />
  <select
    :value="unit"
    :disabled="disabled"
    class="mb-0 text-sm disabled:outline-n-weak disabled:opacity-40"
    @change="onUnitSelected"
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
