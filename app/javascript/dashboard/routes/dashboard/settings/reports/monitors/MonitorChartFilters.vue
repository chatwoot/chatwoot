<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  pausedAt: { type: Number, default: null },
});
const filters = defineModel({ type: Object, required: true });

const RANGE_DAYS = [7, 15, 30];
const INTERVALS = ['hour', 'six_hours', 'day'];

const { t } = useI18n();

const rangeLabel = count =>
  props.pausedAt
    ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { count })
    : t('MONITORS.LAST_DAYS', { count });
const intervalLabel = interval =>
  t(`MONITORS.INTERVALS.${interval.toUpperCase()}`);

const rangeOptions = computed(() =>
  RANGE_DAYS.map(days => ({ value: String(days), label: rangeLabel(days) }))
);
const intervalOptions = computed(() =>
  INTERVALS.map(value => ({ value, label: intervalLabel(value) }))
);

const update = changes => {
  filters.value = { ...filters.value, ...changes };
};
</script>

<template>
  <div class="flex items-center gap-2">
    <SelectMenu
      :model-value="String(filters.range)"
      :options="rangeOptions"
      :label="rangeLabel(filters.range)"
      sub-menu-position="bottom"
      @update:model-value="range => update({ range: Number(range) })"
    />
    <SelectMenu
      :model-value="filters.interval"
      :options="intervalOptions"
      :label="
        t('MONITORS.GROUP_BY', { interval: intervalLabel(filters.interval) })
      "
      sub-menu-position="bottom"
      @update:model-value="interval => update({ interval })"
    />
  </div>
</template>
