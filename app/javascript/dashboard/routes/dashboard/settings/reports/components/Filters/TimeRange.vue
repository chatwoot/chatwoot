<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['timeRangeChanged']);
const { t } = useI18n();

const timeFrom = ref('00:00');
const timeTo = ref('23:59');

watch(
  [timeFrom, timeTo],
  () => {
    emit('timeRangeChanged', {
      since: timeFrom.value,
      until: timeTo.value,
    });
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex gap-1">
    <input v-model="timeFrom" type="time" class="multiselect-wrap--small" />

    <span class="text-n-slate-10 py-3 text-sm">{{
      t('AGENT_ACTIVITY_REPORTS.FILTERS.TIME_RANGE_SEPARATOR')
    }}</span>

    <input v-model="timeTo" type="time" class="multiselect-wrap--small" />

    <span class="text-xs text-n-slate-10 ml-2">{{
      t('AGENT_ACTIVITY_REPORTS.FILTERS.TIME_ZONE_UTC')
    }}</span>
  </div>
</template>
