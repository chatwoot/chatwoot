<script setup>
import { computed, onMounted, ref } from 'vue';
import { useToggle } from '@vueuse/core';

import MetricCard from './overview/MetricCard.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';
import ReportsAPI from 'dashboard/api/reports';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';
const { t } = useI18n();

const uiFlags = useMapGetter('getOverviewUIFlags');
const agentStatus = useMapGetter('agents/getAgentStatus');
const accountConversationMetric = useMapGetter('getAccountConversationMetric');
const store = useStore();

const teams = useMapGetter('teams/getTeams');

const downloadReports = async () => {
  const { since, until, businessHours } = store.state.reports;

  const response = await ReportsAPI.getOverviewReports({
    since,
    until,
    businessHours,
  });

  downloadCsvFile('overview_summary', response.data);
};

const teamMenuList = computed(() => {
  return [
    { label: t('OVERVIEW_REPORTS.TEAM_CONVERSATIONS.ALL_TEAMS'), value: null },
    ...teams.value.map(team => ({ label: team.name, value: team.id })),
  ];
});

const agentStatusMetrics = computed(() => {
  const metric = {};

  const I18N_MAP = {
    online: 'OVERVIEW_REPORTS.AGENT_STATUS.ONLINE',
    offline: 'OVERVIEW_REPORTS.AGENT_STATUS.OFFLINE',
    busy: 'OVERVIEW_REPORTS.AGENT_STATUS.BUSY',
  };

  Object.keys(agentStatus.value).forEach(key => {
    const i18nKey = I18N_MAP[key];
    if (!i18nKey) return;

    metric[t(i18nKey)] = agentStatus.value[key];
  });

  return metric;
});

const conversationMetrics = computed(() => {
  const metric = {};

  const I18N_MAP = {
    open: 'OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.OPEN',
    resolved: 'OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.RESOLVED',
    pending: 'OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.PENDING',
  };

  Object.keys(accountConversationMetric.value).forEach(key => {
    const i18nKey = I18N_MAP[key];
    if (!i18nKey) return;

    metric[t(i18nKey)] = accountConversationMetric.value[key];
  });

  return metric;
});

const selectedTeam = ref(null);
const selectedTeamLabel = computed(() => {
  const team =
    teamMenuList.value.find(
      menuItem => menuItem.value === selectedTeam.value
    ) || {};
  return team.label;
});
const fetchData = () => {
  const params = {};
  if (selectedTeam.value) {
    params.team_id = selectedTeam.value;
  }
  store.dispatch('fetchAccountConversationMetric', params);
};

const { startRefetching } = useLiveRefresh(fetchData);
const [showDropdown, toggleDropdown] = useToggle();

const handleAction = ({ value }) => {
  toggleDropdown(false);
  selectedTeam.value = value;
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
  <div class="flex flex-col items-center md:flex-row gap-4">
    <div
      class="flex-1 w-full max-w-full md:w-[65%] md:max-w-[65%] conversation-metric"
    >
      <MetricCard
        :header="t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.HEADER')"
        :is-loading="uiFlags.isFetchingAccountConversationMetric"
        :loading-message="
          t('OVERVIEW_REPORTS.ACCOUNT_CONVERSATIONS.LOADING_MESSAGE')
        "
      >
        <template v-if="teams.length" #control>
          <div
            v-on-clickaway="() => toggleDropdown(false)"
            class="relative flex items-center group z-50"
          >
            <Button
              sm
              slate
              faded
              :label="selectedTeamLabel"
              class="capitalize rounded-md group-hover:bg-n-alpha-2"
              @click="toggleDropdown()"
            />
            <DropdownMenu
              v-if="showDropdown"
              :menu-items="teamMenuList"
              class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full"
              label-class="capitalize"
              @action="handleAction($event)"
            />
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
