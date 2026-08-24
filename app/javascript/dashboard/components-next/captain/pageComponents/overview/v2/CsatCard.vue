<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import MetricCard from 'dashboard/components-next/captain/pageComponents/overview/MetricCard.vue';
import OverviewPanel from './OverviewPanel.vue';

const props = defineProps({
  autonomous: { type: Object, default: null },
  assisted: { type: Object, default: null },
  humanOnly: { type: Object, default: null },
  loading: { type: Boolean, default: false },
});

const { t } = useI18n();

const formatScore = value => Number(value || 0).toFixed(1);
const formatTrend = value => {
  const numericValue = Number(value || 0);
  if (numericValue === 0) return '0';
  const sign = numericValue > 0 ? '+' : '';
  return `${sign}${numericValue.toFixed(1)}`;
};

const comparison = score => {
  const humanOnlyScore = props.humanOnly?.current;
  if (humanOnlyScore === null || humanOnlyScore === undefined) return '';

  const delta = Number(score?.current || 0) - Number(humanOnlyScore);
  return t('CAPTAIN.OVERVIEW.V2.CSAT.VS_HUMANS', {
    value: formatTrend(delta),
  });
};

const metricFor = (key, label, hint, score) => ({
  key,
  label,
  hint,
  value: formatScore(score?.current),
  trend: formatTrend(score?.trend),
  trendGood: Number(score?.trend || 0) === 0 ? null : score.trend > 0,
  trendUp: Number(score?.trend || 0) === 0 ? null : score.trend > 0,
  description: comparison(score),
  valueClass: 'text-n-blue-11',
});

const metrics = computed(() => [
  metricFor(
    'autonomous',
    t('CAPTAIN.OVERVIEW.V2.CSAT.AUTONOMOUS'),
    t('CAPTAIN.OVERVIEW.V2.CSAT.AUTONOMOUS_HINT'),
    props.autonomous
  ),
  metricFor(
    'assisted',
    t('CAPTAIN.OVERVIEW.V2.CSAT.ASSISTED'),
    t('CAPTAIN.OVERVIEW.V2.CSAT.ASSISTED_HINT'),
    props.assisted
  ),
]);
</script>

<template>
  <OverviewPanel
    :title="$t('CAPTAIN.OVERVIEW.V2.CSAT.TITLE')"
    border-class="border-n-weak"
    :shadow="false"
  >
    <div class="grid grid-rows-[repeat(2,8.875rem)]">
      <MetricCard
        v-for="(metric, index) in metrics"
        :key="metric.key"
        v-bind="metric"
        layout="spread"
        :loading="loading"
        :class="index === 0 ? 'border-b border-n-weak' : ''"
      />
    </div>
  </OverviewPanel>
</template>
