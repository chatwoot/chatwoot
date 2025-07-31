<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import ReportMetricCard from 'dashboard/routes/dashboard/settings/reports/components/ReportMetricCard.vue';
import DateRange from 'dashboard/routes/dashboard/settings/reports/components/Filters/DateRange.vue';
import Agents from 'dashboard/routes/dashboard/settings/reports/components/Filters/Agents.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Table from 'dashboard/components/table/Table.vue';
import BarChart from 'shared/components/charts/BarChart.vue';
// LineChart and PieChart will be replaced with BarChart

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();

const metrics = computed(() => getters['assignmentMetrics/getMetrics'].value);
const agentHistory = computed(
  () => getters['assignmentMetrics/getAgentHistory'].value
);
const policyPerformance = computed(
  () => getters['assignmentMetrics/getPolicyPerformance'].value
);
const agentUtilization = computed(
  () => getters['assignmentMetrics/getAgentUtilization'].value
);
const uiFlags = computed(() => getters['assignmentMetrics/getUIFlags'].value);
const assignmentPolicies = computed(
  () => getters['assignmentPolicies/getAssignmentPolicies'].value
);

const filters = ref({
  startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
    .toISOString()
    .split('T')[0],
  endDate: new Date().toISOString().split('T')[0],
  agentIds: [],
  policyIds: [],
  groupBy: 'day',
});

const exportType = ref('overview');
const activeTab = ref('overview');

const tabs = [
  { key: 'overview', label: t('ASSIGNMENT_SETTINGS.METRICS.TABS.OVERVIEW') },
  {
    key: 'agent_performance',
    label: t('ASSIGNMENT_SETTINGS.METRICS.TABS.AGENT_PERFORMANCE'),
  },
  {
    key: 'policy_performance',
    label: t('ASSIGNMENT_SETTINGS.METRICS.TABS.POLICY_PERFORMANCE'),
  },
  {
    key: 'utilization',
    label: t('ASSIGNMENT_SETTINGS.METRICS.TABS.UTILIZATION'),
  },
];

const agentHistoryColumns = [
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.AGENT'),
    key: 'agent',
    width: '25%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.ASSIGNMENTS_HANDLED'),
    key: 'assignments_handled',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.AVG_RESPONSE_TIME'),
    key: 'avg_response_time',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.SATISFACTION_SCORE'),
    key: 'satisfaction_score',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.EFFICIENCY_SCORE'),
    key: 'efficiency_score',
    width: '15%',
  },
];

const policyPerformanceColumns = [
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.POLICY'),
    key: 'policy',
    width: '30%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.TOTAL_ASSIGNMENTS'),
    key: 'total_assignments',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.SUCCESS_RATE'),
    key: 'success_rate',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.AVG_HANDLING_TIME'),
    key: 'avg_handling_time',
    width: '20%',
  },
  {
    title: t('ASSIGNMENT_SETTINGS.METRICS.TABLE.REASSIGNMENT_RATE'),
    key: 'reassignment_rate',
    width: '10%',
  },
];

const applyFilters = () => {
  store.dispatch('assignmentMetrics/setFilters', filters.value);
};

onMounted(() => {
  store.dispatch('assignmentPolicies/get');
  applyFilters();
});

watch(
  filters,
  () => {
    applyFilters();
  },
  { deep: true }
);

const exportReport = async () => {
  try {
    await store.dispatch('assignmentMetrics/exportReport', exportType.value);
  } catch (error) {
    // Export failed
  }
};

const formatTime = seconds => {
  if (!seconds) return '-';
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}m ${remainingSeconds}s`;
};

const getAssignmentTrendData = computed(() => {
  const trends = getters['assignmentMetrics/getAssignmentTrends'].value || [];
  return {
    labels: trends.map(trend => new Date(trend.date).toLocaleDateString()),
    datasets: [
      {
        label: t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.ASSIGNMENTS'),
        data: trends.map(trend => trend.total_assignments),
        borderColor: 'rgb(99, 102, 241)',
        backgroundColor: 'rgba(99, 102, 241, 0.1)',
      },
    ],
  };
});

const getUtilizationChartData = computed(() => {
  const utilization = agentUtilization.value || [];
  return {
    labels: utilization.map(a => a.agent_name),
    datasets: [
      {
        label: t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.UTILIZATION'),
        data: utilization.map(a => a.utilization_percentage),
        backgroundColor: [
          'rgba(99, 102, 241, 0.8)',
          'rgba(34, 197, 94, 0.8)',
          'rgba(251, 146, 60, 0.8)',
          'rgba(239, 68, 68, 0.8)',
          'rgba(168, 85, 247, 0.8)',
        ],
      },
    ],
  };
});

const getPolicyDistributionData = computed(() => {
  const performance = policyPerformance.value || [];
  return {
    labels: performance.map(p => p.policy_name),
    datasets: [
      {
        data: performance.map(p => p.total_assignments),
        backgroundColor: [
          'rgba(99, 102, 241, 0.8)',
          'rgba(34, 197, 94, 0.8)',
          'rgba(251, 146, 60, 0.8)',
          'rgba(239, 68, 68, 0.8)',
          'rgba(168, 85, 247, 0.8)',
        ],
      },
    ],
  };
});
</script>

<template>
  <div>
    <BaseSettingsHeader
      :title="$t('ASSIGNMENT_SETTINGS.METRICS.HEADER')"
      :description="$t('ASSIGNMENT_SETTINGS.METRICS.SUBHEADER')"
    />

    <div class="p-8">
      <!-- Filters -->
      <div
        class="bg-white rounded-lg shadow-sm border border-slate-200 p-6 mb-6"
      >
        <h3 class="text-lg font-medium mb-4">
          {{ $t('ASSIGNMENT_SETTINGS.METRICS.FILTERS.TITLE') }}
        </h3>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <DateRange
            v-model:start-date="filters.startDate"
            v-model:end-date="filters.endDate"
          />

          <Agents
            v-model="filters.agentIds"
            :label="$t('ASSIGNMENT_SETTINGS.METRICS.FILTERS.AGENTS')"
          />

          <MultiSelect
            v-model="filters.policyIds"
            :options="assignmentPolicies"
            :label="$t('ASSIGNMENT_SETTINGS.METRICS.FILTERS.POLICIES')"
            :placeholder="
              $t('ASSIGNMENT_SETTINGS.METRICS.FILTERS.POLICIES_PLACEHOLDER')
            "
            track-by="id"
            label-key="name"
          />

          <div class="flex items-end">
            <Button
              variant="primary"
              size="medium"
              icon="download"
              :loading="uiFlags.isExporting"
              @click="exportReport"
            >
              {{ $t('ASSIGNMENT_SETTINGS.METRICS.EXPORT') }}
            </Button>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="mb-6">
        <div class="flex gap-4 border-b border-slate-200">
          <button
            v-for="tab in tabs"
            :key="tab.key"
            class="px-4 py-2 text-sm font-medium transition-colors"
            :class="[
              activeTab === tab.key
                ? 'text-woot-600 border-b-2 border-woot-600'
                : 'text-slate-600 hover:text-slate-900',
            ]"
            @click="activeTab = tab.key"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center h-64"
      >
        <Spinner size="large" />
      </div>

      <!-- Overview Tab -->
      <div v-else-if="activeTab === 'overview'" class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <ReportMetricCard
            :title="$t('ASSIGNMENT_SETTINGS.METRICS.CARDS.TOTAL_ASSIGNMENTS')"
            :value="
              (metrics.overview && metrics.overview.total_assignments) || 0
            "
            icon="chat"
          />

          <ReportMetricCard
            :title="$t('ASSIGNMENT_SETTINGS.METRICS.CARDS.AVG_RESPONSE_TIME')"
            :value="
              formatTime(
                (metrics.overview && metrics.overview.avg_response_time) || 0
              )
            "
            icon="clock"
          />

          <ReportMetricCard
            :title="$t('ASSIGNMENT_SETTINGS.METRICS.CARDS.SATISFACTION_SCORE')"
            :value="`${(metrics.overview && metrics.overview.satisfaction_score) || 0}%`"
            icon="emoji-happy"
          />

          <ReportMetricCard
            :title="$t('ASSIGNMENT_SETTINGS.METRICS.CARDS.REASSIGNMENT_RATE')"
            :value="`${(metrics.overview && metrics.overview.reassignment_rate) || 0}%`"
            icon="refresh"
          />
        </div>

        <div class="bg-white rounded-lg shadow-sm border border-slate-200 p-6">
          <h3 class="text-lg font-medium mb-4">
            {{ $t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.ASSIGNMENT_TRENDS') }}
          </h3>
          <BarChart
            :data="getAssignmentTrendData"
            :chart-options="{ height: 300 }"
          />
        </div>
      </div>

      <!-- Agent Performance Tab -->
      <div v-else-if="activeTab === 'agent_performance'" class="space-y-6">
        <Table :columns="agentHistoryColumns" :data="agentHistory">
          <template #agent="{ row }">
            <div class="flex items-center gap-2">
              <img
                :src="row.agent_avatar"
                :alt="row.agent_name"
                class="w-8 h-8 rounded-full"
              />
              <span class="font-medium">{{ row.agent_name }}</span>
            </div>
          </template>

          <template #assignments_handled="{ row }">
            <span class="font-medium">{{ row.assignments_handled }}</span>
          </template>

          <template #avg_response_time="{ row }">
            {{ formatTime(row.avg_response_time) }}
          </template>

          <template #satisfaction_score="{ row }">
            <div class="flex items-center gap-2">
              <span>{{ row.satisfaction_score }}</span>
              <div class="w-16 h-2 bg-slate-200 rounded-full overflow-hidden">
                <div
                  class="h-full bg-green-500"
                  :style="{ width: `${row.satisfaction_score}%` }"
                />
              </div>
            </div>
          </template>

          <template #efficiency_score="{ row }">
            <span
              class="font-medium"
              :class="[
                row.efficiency_score >= 80
                  ? 'text-green-600'
                  : row.efficiency_score >= 60
                    ? 'text-yellow-600'
                    : 'text-red-600',
              ]"
            >
              {{ row.efficiency_score }}
            </span>
          </template>
        </Table>
      </div>

      <!-- Policy Performance Tab -->
      <div v-else-if="activeTab === 'policy_performance'" class="space-y-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">
              {{ $t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.POLICY_DISTRIBUTION') }}
            </h3>
            <BarChart
              :data="getPolicyDistributionData"
              :chart-options="{ height: 300 }"
            />
          </div>

          <div
            class="bg-white rounded-lg shadow-sm border border-slate-200 p-6"
          >
            <h3 class="text-lg font-medium mb-4">
              {{
                $t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.POLICY_SUCCESS_RATES')
              }}
            </h3>
            <BarChart
              :data="{
                labels: (policyPerformance || []).map(p => p.policy_name),
                datasets: [
                  {
                    label: t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.SUCCESS_RATE'),
                    data: (policyPerformance || []).map(p => p.success_rate),
                    backgroundColor: 'rgba(34, 197, 94, 0.8)',
                  },
                ],
              }"
              :height="300"
            />
          </div>
        </div>

        <Table :columns="policyPerformanceColumns" :data="policyPerformance">
          <template #policy="{ row }">
            <span class="font-medium">{{ row.policy_name }}</span>
          </template>

          <template #total_assignments="{ row }">
            {{ row.total_assignments }}
          </template>

          <template #success_rate="{ row }">
            <span
              class="font-medium"
              :class="[
                row.success_rate >= 90
                  ? 'text-green-600'
                  : row.success_rate >= 70
                    ? 'text-yellow-600'
                    : 'text-red-600',
              ]"
            >
              {{ row.success_rate }}
            </span>
          </template>

          <template #avg_handling_time="{ row }">
            {{ formatTime(row.avg_handling_time) }}
          </template>

          <template #reassignment_rate="{ row }">
            {{ row.reassignment_rate }}
          </template>
        </Table>
      </div>

      <!-- Utilization Tab -->
      <div v-else-if="activeTab === 'utilization'" class="space-y-6">
        <div class="bg-white rounded-lg shadow-sm border border-slate-200 p-6">
          <h3 class="text-lg font-medium mb-4">
            {{ $t('ASSIGNMENT_SETTINGS.METRICS.CHARTS.AGENT_UTILIZATION') }}
          </h3>
          <BarChart
            :data="getUtilizationChartData"
            :height="400"
            :options="{
              indexAxis: 'y',
              responsive: true,
              maintainAspectRatio: false,
              scales: {
                x: {
                  beginAtZero: true,
                  max: 100,
                },
              },
            }"
          />
        </div>
      </div>
    </div>
  </div>
</template>
