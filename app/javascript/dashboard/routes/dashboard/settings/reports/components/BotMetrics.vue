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

const formatToPercent = value => {
  return value ? `${value}%` : '--';
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
  });
};

watch(() => props.filters, fetchMetrics, { deep: true });

onMounted(fetchMetrics);
</script>

<template>
  <div
    class="flex flex-wrap mx-0 bg-white dark:bg-slate-800 rounded-[4px] p-4 mb-5 border border-solid border-slate-75 dark:border-slate-700"
  >
    <report-metric-card
      :label="$t('BOT_REPORTS.METRIC.TOTAL_CONVERSATIONS.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.TOTAL_CONVERSATIONS.TOOLTIP')"
      :value="conversationCount"
      class="flex-1"
    />
    <report-metric-card
      :label="$t('BOT_REPORTS.METRIC.TOTAL_RESPONSES.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.TOTAL_RESPONSES.TOOLTIP')"
      :value="messageCount"
      class="flex-1"
    />
    <report-metric-card
      :label="$t('BOT_REPORTS.METRIC.RESOLUTION_RATE.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.RESOLUTION_RATE.TOOLTIP')"
      :value="formatToPercent(resolutionRate)"
      class="flex-1"
    />
    <report-metric-card
      :label="$t('BOT_REPORTS.METRIC.HANDOFF_RATE.LABEL')"
      :info-text="$t('BOT_REPORTS.METRIC.HANDOFF_RATE.TOOLTIP')"
      :value="formatToPercent(handoffRate)"
      class="flex-1"
    />
  </div>
</template>
