<script setup>
import { computed, onMounted, ref } from 'vue';
import MetricCard from './overview/MetricCard.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import FilterSelector from 'dashboard/routes/dashboard/settings/reports/components/FilterSelector.vue';
import { useI18n } from 'vue-i18n';
import ReportsAPI from 'dashboard/api/reports';
import { downloadFile } from 'dashboard/helper/downloadHelper';

const { t } = useI18n();
const uiFlags = useMapGetter('getOverviewUIFlags');
const agentStatus = useMapGetter('agents/getAgentStatus');
const accountConversationMetric = useMapGetter('getAccountConversationMetric');
const store = useStore();

const selectedTeams = ref([]);
const selectedAgents = ref([]);
const selectedInboxes = ref([]);
const dateFilter = ref({
  from: null,
  to: null,
});
const timeRange = ref({
  since: '00:00',
  until: '23:59',
});

const downloadReports = async (format = 'csv') => {
  const params = {
    from: dateFilter.value.from,
    to: dateFilter.value.to,
    format,
  };

  if (selectedTeams.value.length > 0) {
    params.teamIds = selectedTeams.value.map(team => team.id);
  }

  if (selectedAgents.value.length > 0) {
    params.userIds = selectedAgents.value.map(agent => agent.id);
  }

  if (selectedInboxes.value.length > 0) {
    params.inboxIds = selectedInboxes.value.map(inbox => inbox.id);
  }

  if (timeRange.value.since !== '00:00') {
    params.timeSince = timeRange.value.since;
  }

  if (timeRange.value.until !== '23:59') {
    params.timeUntil = timeRange.value.until;
  }

  const response = await ReportsAPI.getOverviewReports(params);

  downloadFile(
    `overview_summary_${new Date().getTime()}.${format}`,
    response.data,
    format
  );
};

const agentStatusMetrics = computed(() => {
  const metric = {};
  const statusMap = {
    online: t('OVERVIEW_REPORTS.AGENT_STATUS.ONLINE'),
    offline: t('OVERVIEW_REPORTS.AGENT_STATUS.OFFLINE'),
    busy: t('OVERVIEW_REPORTS.AGENT_STATUS.BUSY'),
  };

  Object.keys(agentStatus.value).forEach(key => {
    if (statusMap[key]) {
      metric[statusMap[key]] = agentStatus.value[key];
    }
  });
  return metric;
});

const conversationMetrics = computed(() => {
  const metric = {};
  const conversationMap = {
    open: t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.OPEN'),
    resolved: t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.RESOLVED'),
    pending: t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.PENDING'),
  };

  Object.keys(accountConversationMetric.value).forEach(key => {
    if (conversationMap[key]) {
      metric[conversationMap[key]] = accountConversationMetric.value[key];
    }
  });
  return metric;
});

const fetchData = () => {
  const params = {};

  if (selectedTeams.value.length > 0) {
    params.team_ids = selectedTeams.value.map(team => team.id);
  }

  if (selectedAgents.value.length > 0) {
    params.user_ids = selectedAgents.value.map(agent => agent.id);
  }

  if (selectedInboxes.value.length > 0) {
    params.inbox_ids = selectedInboxes.value.map(inbox => inbox.id);
  }

  if (dateFilter.value.from) {
    params.since = dateFilter.value.from;
  }

  if (dateFilter.value.to) {
    params.until = dateFilter.value.to;
  }

  store.dispatch('fetchAccountConversationMetric', params);
};

const { startRefetching } = useLiveRefresh(fetchData);

const handleFilterChange = filters => {
  dateFilter.value = {
    from: filters.from,
    to: filters.to,
  };

  if (filters.selectedTeam) {
    selectedTeams.value = filters.selectedTeam;
  }

  if (filters.selectedAgents) {
    selectedAgents.value = filters.selectedAgents;
  }

  if (filters.selectedInbox) {
    selectedInboxes.value = filters.selectedInbox;
  }

  if (filters.timeRange) {
    timeRange.value = filters.timeRange;
  }

  fetchData();
};

onMounted(() => {
  fetchData();
  startRefetching();
});

defineExpose({
  downloadReports,
});
</script>

<template>
  <div class="flex flex-col items-stretch md:flex-row gap-4">
    <div
      class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
    >
      <MetricCard
        :header="t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
        :is-loading="uiFlags.isFetchingAccountConversationMetric"
        :loading-message="
          t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
        "
        :use-grid-layout="false"
      >
        <template #control>
          <div class="flex gap-2 flex-wrap w-full">
            <div class="w-full">
              <FilterSelector
                show-time-range-filter
                show-agents-filter
                show-inbox-filter
                show-team-filter
                :show-business-hours-switch="false"
                @filter-change="handleFilterChange"
              />
            </div>
          </div>
        </template>
        <div
          v-for="(metric, name, index) in conversationMetrics"
          :key="index"
          class="flex-1 min-w-0 pb-2"
        >
          <h3 class="text-base text-n-slate-11">
            {{ name }}
          </h3>
          <p class="text-n-slate-12 text-3xl mb-0 mt-1">
            {{ metric }}
          </p>
        </div>
      </MetricCard>
    </div>
    <div class="flex-1 w-full max-w-full md:w-[35%] md:max-w-[35%]">
      <MetricCard :header="$t('OVERVIEW_REPORTS.AGENT_STATUS.HEADER')">
        <div
          v-for="(metric, name, index) in agentStatusMetrics"
          :key="index"
          class="flex-1 min-w-0 pb-2"
        >
          <h3 class="text-base text-n-slate-11">
            {{ name }}
          </h3>
          <p class="text-n-slate-12 text-3xl mb-0 mt-1">
            {{ metric }}
          </p>
        </div>
      </MetricCard>
    </div>
  </div>
</template>
