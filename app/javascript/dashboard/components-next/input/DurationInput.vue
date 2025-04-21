<script setup>
import { computed, ref } from 'vue';
import Input from './Input.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  min: { type: Number, default: 0 },
  max: { type: Number, default: Infinity },
});

const { t } = useI18n();
const duration = defineModel('value', { type: Number, default: null });

const UNIT_TYPES = {
  MINUTES: 'minutes',
  HOURS: 'hours',
  DAYS: 'days',
};
const unit = ref(UNIT_TYPES.MINUTES);

const transformedValue = computed({
  get() {
    if (unit.value === UNIT_TYPES.MINUTES) return duration.value;
    if (unit.value === UNIT_TYPES.HOURS) return duration.value / 60;
    if (unit.value === UNIT_TYPES.DAYS) return duration.value / 24 / 60;

    return 0;
  },
  set(newValue) {
    let minuteValue;
    if (unit.value === UNIT_TYPES.MINUTES) {
      minuteValue = newValue;
    } else if (unit.value === UNIT_TYPES.HOURS) {
      minuteValue = newValue * 60;
    } else if (unit.value === UNIT_TYPES.DAYS) {
      minuteValue = newValue * 24 * 60;
    }

    duration.value = Math.min(Math.max(minuteValue, props.min), props.max);
  },
});
</script>

<template>
  <Input
    v-model="transformedValue"
    :placeholder="t('DURATION_INPUT.PLACEHOLDER')"
    class="flex-grow w-full"
  />
  <select v-model="unit" class="mb-0">
    <option :value="UNIT_TYPES.MINUTES">
      {{ t('DURATION_INPUT.MINUTES') }}
    </option>
    <option :value="UNIT_TYPES.HOURS">{{ t('DURATION_INPUT.HOURS') }}</option>
    <option :value="UNIT_TYPES.DAYS">{{ t('DURATION_INPUT.DAYS') }}</option>
  </select>
</template>
