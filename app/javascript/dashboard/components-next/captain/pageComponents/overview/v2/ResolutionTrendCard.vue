<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { LineChart } from '@chatwoot/viz';
import OverviewPanel from './OverviewPanel.vue';

const props = defineProps({
  trend: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const { t, locale } = useI18n();

const formatDate = value =>
  new Intl.DateTimeFormat(locale.value, {
    month: 'short',
    day: '2-digit',
  }).format(new Date(`${value}T00:00:00`));

const formatDay = value =>
  new Intl.DateTimeFormat(locale.value, {
    day: '2-digit',
  }).format(new Date(`${value}T00:00:00`));

const bucketLabel = bucket => {
  const start = formatDate(bucket.starts_on);
  const end = formatDate(bucket.ends_on);
  const startsOn = new Date(`${bucket.starts_on}T00:00:00`);
  const endsOn = new Date(`${bucket.ends_on}T00:00:00`);
  const sameMonth =
    startsOn.getFullYear() === endsOn.getFullYear() &&
    startsOn.getMonth() === endsOn.getMonth();

  return start === end
    ? start
    : `${start} - ${sameMonth ? formatDay(bucket.ends_on) : end}`;
};

const chartData = computed(() => {
  const buckets = props.trend?.buckets || [];
  return {
    categories: buckets.map(bucketLabel),
    series: [
      {
        id: 'handled',
        label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.HANDLED'),
        color: 'rgb(var(--slate-7))',
        pointBorderColor: 'rgb(var(--card-color))',
        valueColor: 'rgb(var(--slate-10))',
        data: buckets.map(bucket => bucket.conversations_handled),
      },
      {
        id: 'resolved',
        label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.RESOLVED'),
        color: 'rgb(var(--teal-9))',
        pointBorderColor: 'rgb(var(--card-color))',
        valueColor: 'rgb(var(--teal-11))',
        data: buckets.map(bucket => bucket.resolved_by_captain),
      },
    ],
  };
});

const hasData = computed(() => chartData.value.categories.length > 0);
const formatCount = value => Number(value).toLocaleString();
</script>

<template>
  <OverviewPanel :title="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.TITLE')">
    <div class="min-w-0 px-5 pb-5 pt-8">
      <div
        v-if="loading"
        class="h-[232px] rounded-lg bg-n-slate-3 animate-pulse"
      />
      <LineChart
        v-else-if="hasData"
        :data="chartData"
        :format-value="formatCount"
        :height="232"
        :point-radius="3"
        :aria-label="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.ARIA_LABEL')"
        class="[--cw-viz-line-label-color:rgb(var(--slate-11))] [--cw-viz-line-axis-color:rgb(var(--slate-4))] [--cw-viz-line-axis-font-size:12px] [--cw-viz-line-value-font-size:12px] [--cw-viz-line-width:1px] [--cw-viz-line-point-border-width:4px] [--cw-viz-line-tooltip-background:rgb(var(--solid-2))] [--cw-viz-line-tooltip-color:rgb(var(--slate-12))] [--cw-viz-line-tooltip-border-color:rgb(var(--border-strong))] [&_.cw-viz-line__axis-label]:font-[440] [&_.cw-viz-line__axis-label]:tracking-[-0.24px] [&_.cw-viz-line__value]:font-[440] [&_.cw-viz-line__value]:tracking-[-0.24px]"
      />
      <div
        v-else
        class="grid h-[232px] text-sm place-content-center text-n-slate-11"
      >
        {{ $t('CAPTAIN.OVERVIEW.V2.EMPTY') }}
      </div>
    </div>
  </OverviewPanel>
</template>
