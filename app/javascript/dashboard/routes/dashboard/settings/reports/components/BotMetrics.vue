<script setup>
import { ref, watch, onMounted } from 'vue';
import ReportMetricCard from './ReportMetricCard.vue';
import ReportsAPI from 'dashboard/api/reports';

const props = defineProps({
  filters: {
    type: Object,
    required: true,
  },
});

const conversationCount = ref('0');
const messageCount = ref('0');
const resolutionRate = ref('0');
const handoffRate = ref('0');
const avgResolutionTime = ref(null);

const formatToPercent = value => {
  return value ? `${value}%` : '--';
};

const formatDuration = seconds => {
  if (seconds == null) return '--';
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.round(seconds / 60)}m`;
  const h = Math.floor(seconds / 3600);
  const m = Math.round((seconds % 3600) / 60);
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
};

const fetchMetrics = () => {
  if (!props.filters.to || !props.filters.from) {
    return;
  }
  ReportsAPI.getBotMetrics(props.filters).then(response => {
    conversationCount.value = response.data.conversation_count.toLocaleString();
    messageCount.value = response.data.message_count.toLocaleString();
    resolutionRate.value = response.data.resolution_rate.toString();
    handoffRate.value = response.data.handoff_rate.toString();
    avgResolutionTime.value = response.data.avg_resolution_time;
  });
};

watch(() => props.filters, fetchMetrics, { deep: true });

onMounted(fetchMetrics);
</script>

<template>
  <div
    class="flex flex-wrap mx-0 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-5"
  >
    <ReportMetricCard
      :label="$t('BOT_REPORTS.METRIC.TOTAL_CONVERSATIONS.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.TOTAL_CONVERSATIONS.TOOLTIP')"
      :value="conversationCount"
      class="flex-1"
    />
    <ReportMetricCard
      :label="$t('BOT_REPORTS.METRIC.TOTAL_RESPONSES.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.TOTAL_RESPONSES.TOOLTIP')"
      :value="messageCount"
      class="flex-1"
    />
    <ReportMetricCard
      :label="$t('BOT_REPORTS.METRIC.RESOLUTION_RATE.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.RESOLUTION_RATE.TOOLTIP')"
      :value="formatToPercent(resolutionRate)"
      class="flex-1"
    />
    <ReportMetricCard
      :label="$t('BOT_REPORTS.METRIC.HANDOFF_RATE.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.HANDOFF_RATE.TOOLTIP')"
      :value="formatToPercent(handoffRate)"
      class="flex-1"
    />
    <ReportMetricCard
      :label="$t('BOT_REPORTS.METRIC.AVG_RESOLUTION_TIME.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.AVG_RESOLUTION_TIME.TOOLTIP')"
      :value="formatDuration(avgResolutionTime)"
      class="flex-1"
    />
  </div>
</template>
