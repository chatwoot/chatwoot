<script setup>
import { computed } from 'vue';
import { HeatmapChart } from '@chatwoot/viz';

import getDay from 'date-fns/getDay';

import { groupHeatmapByDay } from 'helpers/ReportsDataHelper';
import { useI18n } from 'vue-i18n';
import { formatLocalized } from 'shared/helpers/localizedDate';

const props = defineProps({
  heatmapData: {
    type: Array,
    default: () => [],
  },
  numberOfRows: {
    type: Number,
    default: 7,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  colorScheme: {
    type: String,
    default: 'blue',
    validator: value => ['blue', 'green'].includes(value),
  },
  ariaLabel: {
    type: String,
    required: true,
  },
  formatValue: {
    type: Function,
    required: true,
  },
});
const { t } = useI18n();

function formatDate(dateString) {
  return formatLocalized(new Date(dateString), 'MMM d, yyyy');
}

// Translated inside the computed below, not once at setup: the page can mount
// before the user's language is applied, and a setup-time label stays English.
const dayNames = () => [
  t('DAYS_OF_WEEK.SUNDAY'),
  t('DAYS_OF_WEEK.MONDAY'),
  t('DAYS_OF_WEEK.TUESDAY'),
  t('DAYS_OF_WEEK.WEDNESDAY'),
  t('DAYS_OF_WEEK.THURSDAY'),
  t('DAYS_OF_WEEK.FRIDAY'),
  t('DAYS_OF_WEEK.SATURDAY'),
];

const columns = Array.from({ length: 24 }, (_, hour) => ({
  id: hour,
  label: `${String(hour).padStart(2, '0')}:00`,
}));

const QUANTILES = [0.2, 0.4, 0.6, 0.8, 0.9, 0.99];

const COLOR_SCHEMES = {
  blue: [
    'rgb(var(--blue-3))',
    'rgb(var(--blue-5))',
    'rgb(var(--blue-7))',
    'rgb(var(--blue-8))',
    'rgb(var(--blue-9))',
    'rgb(var(--blue-10))',
    'rgb(var(--blue-11))',
  ],
  green: [
    'rgb(var(--teal-3))',
    'rgb(var(--teal-5))',
    'rgb(var(--teal-7))',
    'rgb(var(--teal-8))',
    'rgb(var(--teal-9))',
    'rgb(var(--teal-10))',
    'rgb(var(--teal-11))',
  ],
};

const chartData = computed(() => {
  const groupedData = groupHeatmapByDay(props.heatmapData);
  const daysOfWeek = dayNames();
  const rows = Array.from(groupedData.entries()).map(([dateKey, rowData]) => {
    const valuesByHour = new Map(rowData.map(item => [item.hour, item]));
    const date = new Date(dateKey);

    return {
      id: dateKey,
      label: daysOfWeek[getDay(date)],
      description: formatDate(dateKey),
      data: columns.map(({ id }) => valuesByHour.get(id) ?? null),
    };
  });

  return { columns, rows };
});

// The day and date are in the user's language, and their length varies a lot
// ("Wed" / "Quarta-feira", "Apr 1, 2026" / "1 de abr. de 2026"). A fixed column
// wraps the longer ones into the row below, so size it to the widest label.
const MIN_ROW_LABEL_WIDTH = 96;
// The chart's own 0.75rem right padding, plus a little room for rounding.
const ROW_LABEL_PADDING = 16;
// Without a canvas (tests), estimate from the character count.
const FALLBACK_CHAR_WIDTH = 7;

let measureContext;
function textWidth(text, font) {
  if (measureContext === undefined) {
    measureContext =
      document.createElement('canvas').getContext?.('2d') ?? null;
  }
  if (!measureContext) return text.length * FALLBACK_CHAR_WIDTH;
  measureContext.font = font;
  return measureContext.measureText(text).width;
}

const rowLabelWidth = computed(() => {
  const { fontFamily } = getComputedStyle(document.body);
  const widest = Math.max(
    0,
    ...chartData.value.rows.flatMap(row => [
      textWidth(row.label, `600 12px ${fontFamily}`),
      textWidth(row.description, `11px ${fontFamily}`),
    ])
  );
  return Math.max(MIN_ROW_LABEL_WIDTH, Math.ceil(widest) + ROW_LABEL_PADDING);
});

const heatmapColors = computed(() => COLOR_SCHEMES[props.colorScheme]);

const colorSchemeClass = computed(() => {
  return props.colorScheme === 'green'
    ? '[--cw-viz-heatmap-focus-color:rgb(var(--teal-9))]'
    : '[--cw-viz-heatmap-focus-color:rgb(var(--blue-9))]';
});
</script>

<template>
  <div
    v-if="isLoading"
    class="grid relative w-full gap-x-4 gap-y-2.5 overflow-y-scroll md:overflow-visible grid-cols-[5rem_1fr]"
  >
    <div class="grid gap-[0.3125rem] flex-shrink-0">
      <div
        v-for="ii in numberOfRows"
        :key="ii"
        class="w-full rounded-sm bg-n-slate-3 dark:bg-n-slate-1 animate-loader-pulse h-8 min-w-[4.375rem]"
      />
    </div>
    <div class="grid gap-[0.3125rem] w-full min-w-[43.75rem]">
      <div
        v-for="ii in numberOfRows"
        :key="ii"
        class="grid gap-[0.3125rem] grid-cols-[repeat(24,_1fr)]"
      >
        <div
          v-for="jj in 24"
          :key="jj"
          class="w-full h-8 rounded-sm bg-n-slate-3 dark:bg-n-slate-1 animate-loader-pulse"
        />
      </div>
    </div>
    <div />
    <div
      class="grid grid-cols-[repeat(24,_1fr)] gap-[0.3125rem] w-full text-xxxs font-semibold h-5 text-n-slate-11"
    >
      <div v-for="ii in 24" :key="ii" class="flex items-center justify-center">
        {{ ii - 1 }}
      </div>
    </div>
  </div>
  <HeatmapChart
    v-else
    :data="chartData"
    :aria-label="ariaLabel"
    :colors="heatmapColors"
    :format-value="formatValue"
    :quantiles="QUANTILES"
    :cell-min-width="24"
    :gap="5"
    :row-label-width="rowLabelWidth"
    zero-color="rgb(var(--solid-2))"
    class="[--cw-viz-heatmap-level-0-color:rgb(var(--slate-2))] [--cw-viz-heatmap-cell-border-color:rgb(var(--border-strong))] [--cw-viz-heatmap-label-color:rgb(var(--slate-11))] [--cw-viz-heatmap-label-background:rgb(var(--solid-2))] [--cw-viz-heatmap-row-title-color:rgb(var(--slate-12))] [--cw-viz-heatmap-column-label-color:rgb(var(--slate-12))] [--cw-viz-heatmap-tooltip-border-color:rgb(var(--border-strong))] [--cw-viz-heatmap-tooltip-color:rgb(var(--slate-12))] [--cw-viz-heatmap-tooltip-background:rgb(var(--solid-2))] [--cw-viz-heatmap-tooltip-label-color:rgb(var(--slate-11))]"
    :class="colorSchemeClass"
  />
</template>
