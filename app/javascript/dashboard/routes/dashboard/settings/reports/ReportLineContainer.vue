<script setup>
import { computed } from 'vue';
import LineChart from '../../../../../shared/components/charts/LineChart.vue';
import ChartStats2 from './components/ChartElements/ChartStats2.vue';
import { useMapGetter } from 'dashboard/composables/store';
import BarChart2 from '../../../../../shared/components/charts/BarChart2.vue';

const props = defineProps({
  metrics: {
    type: Object,
  },
});

const accountReports = useMapGetter('getAccountReports');

function formatToPercent(value) {
  return Number.isInteger(value) ? `${value}%` : `${value.toFixed(1)}%`;
}

const aiUsage = computed(() => {
  const data1 = accountReports.value?.data?.ai_agent_credit_usage || [];
  const data2 = accountReports.value?.data?.ai_agent_message_send_count || [];
  const totalCreditUsage = props.metrics.aiAgentCreditUsage;
  const totalAiMessageSend = props.metrics.aiAgentMessageSendCount;
  const averageUsage = totalCreditUsage / totalAiMessageSend;
  return {
    data1: {
      label: 'REPORT.METRICS.AI_CREDIT_USE.NAME',
      data: data1,
    },
    data2: {
      label: 'REPORT.METRICS.AI_MESSAGE_SEND.NAME',
      data: data2,
    },
    averageUsage: isFinite(averageUsage) ? averageUsage : 0,
    totalCreditUsage,
    totalAiMessageSend,
  };
});
const agentHandoff = computed(() => {
  const aiAgentHandoffCount = isFinite(props.metrics.aiAgentHandoffCount)
    ? props.metrics.aiAgentHandoffCount
    : 0;
  const handoffRate = isFinite(props.metrics.handoffRate)
    ? props.metrics.handoffRate
    : 0;
  const totalHandoff = aiAgentHandoffCount + handoffRate;
  const handoffRateToHuman = (handoffRate / totalHandoff) * 100;
  return {
    data1: {
      label: 'REPORT.METRICS.HANDOFF_AI_AGENT.NAME',
      data: accountReports.value?.data?.ai_agent_handoff_count || [],
    },
    data2: {
      label: 'REPORT.METRICS.HANDOFF_HUMAN_AGENT.NAME',
      data: accountReports.value?.data?.agent_handoff_count || [],
    },
    handoffRatePercentage: formatToPercent(
      isFinite(handoffRateToHuman) ? handoffRateToHuman : 0
    ),
    aiAgentHandoffCount: aiAgentHandoffCount,
    handoffRate: handoffRate,
  };
});
</script>

<template>
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 px-6 py-5 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <div class="p-4 mb-3 rounded-md">
      <ChartStats2
        :title="$t('REPORT.METRICS.AI_MESSAGE_USAGE.NAME')"
        :desc="`${aiUsage.averageUsage}`"
        :legend1="aiUsage.data1.label"
        :legend1-value="`${aiUsage.totalCreditUsage}`"
        :legend2="aiUsage.data2.label"
        :legend2-value="`${aiUsage.totalAiMessageSend}`"
      />
      <div class="mt-4 h-72">
        <woot-loading-state
          v-if="accountReports.isFetching.ai_agent_message_send_count"
          class="text-xs"
          :message="$t('REPORT.LOADING_CHART')"
        />
        <div v-else class="flex items-center justify-center h-72">
          <LineChart
            v-if="aiUsage.data1.data?.length"
            :data1="aiUsage.data1"
            :data2="aiUsage.data2"
          />
          <span v-else class="text-sm text-slate-600">
            {{ $t('REPORT.NO_ENOUGH_DATA') }}
          </span>
        </div>
      </div>
    </div>
    <div class="p-4 mb-3 rounded-md">
      <ChartStats2
        :title="$t('REPORT.METRICS.AGENT_HANDOFF_RATE.NAME')"
        :desc="`${agentHandoff.handoffRatePercentage}`"
        :legend1="agentHandoff.data1.label"
        :legend1-value="`${agentHandoff.aiAgentHandoffCount}`"
        :legend2="agentHandoff.data2.label"
        :legend2-value="`${agentHandoff.handoffRate}`"
      />
      <div class="mt-4 h-72">
        <woot-loading-state
          v-if="accountReports.isFetching.ai_agent_message_send_count"
          class="text-xs"
          :message="$t('REPORT.LOADING_CHART')"
        />
        <div v-else class="flex items-center justify-center h-72">
          <BarChart2
            v-if="agentHandoff.data1.data?.length"
            :data1="agentHandoff.data1"
            :data2="agentHandoff.data2"
          />
          <span v-else class="text-sm text-slate-600">
            {{ $t('REPORT.NO_ENOUGH_DATA') }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
