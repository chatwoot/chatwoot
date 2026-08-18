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
    day: 'numeric',
  }).format(new Date(`${value}T00:00:00`));

const bucketLabel = bucket => {
  const start = formatDate(bucket.starts_on);
  const end = formatDate(bucket.ends_on);
  return start === end ? start : `${start} – ${end}`;
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
        data: buckets.map(bucket => bucket.conversations_handled),
      },
      {
        id: 'resolved',
        label: t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.RESOLVED'),
        color: 'rgb(var(--teal-9))',
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
    <template #actions>
      <span
        class="px-2.5 py-1 text-xs border rounded-md text-n-slate-11 border-n-weak"
      >
        {{ $t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.MEASURE') }}
      </span>
    </template>
    <div class="min-w-0 p-5">
      <div v-if="loading" class="h-64 rounded-lg bg-n-slate-3 animate-pulse" />
      <LineChart
        v-else-if="hasData"
        :data="chartData"
        :format-value="formatCount"
        :height="260"
        :point-radius="3"
        :aria-label="$t('CAPTAIN.OVERVIEW.V2.RESOLUTION_TREND.ARIA_LABEL')"
        class="[--cw-viz-line-label-color:rgb(var(--slate-11))] [--cw-viz-line-axis-color:rgb(var(--slate-6))] [--cw-viz-line-value-color:rgb(var(--slate-11))] [--cw-viz-line-tooltip-background:rgb(var(--solid-2))] [--cw-viz-line-tooltip-color:rgb(var(--slate-12))] [--cw-viz-line-tooltip-border-color:rgb(var(--border-strong))]"
      />
      <div
        v-else
        class="grid h-64 text-sm place-content-center text-n-slate-11"
      >
        {{ $t('CAPTAIN.OVERVIEW.V2.EMPTY') }}
      </div>
    </div>
  </OverviewPanel>
</template>
