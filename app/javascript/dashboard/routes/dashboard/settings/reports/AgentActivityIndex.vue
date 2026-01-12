<script setup>
import { ref, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import ReportHeader from './components/ReportHeader.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';
import AgentActivityFilters from './components/AgentActivityFilters.vue';
import AgentActivityTimeline from './components/AgentActivityTimeline.vue';

const { t } = useI18n();
const store = useStore();

const now = Date.now();

const filters = ref({
  since: now - 24 * 60 * 60 * 1000,
  until: now,
  hideInactive: false,
  userIds: [],
  teamIds: [],
  inboxIds: [],
});

const fetch = () => {
  const { since, until } = filters.value;

  if (since == null || until == null) {
    return;
  }

  store.dispatch('agentActivity/get', {
    since: Math.floor(since / 1000),
    until: Math.floor(until / 1000),
    hideInactive: filters.value.hideInactive,
    userIds: filters.value.userIds,
    teamIds: filters.value.teamIds,
    inboxIds: filters.value.inboxIds,
  });
};

const onDownloadClick = () => {
  const { since, until } = filters.value;

  if (since == null || until == null) return;

  store.dispatch('downloadAgentActivityReport', {
    since: Math.floor(since / 1000),
    until: Math.floor(until / 1000),
    hideInactive: filters.value.hideInactive,
    userIds: filters.value.userIds,
    teamIds: filters.value.teamIds,
    inboxIds: filters.value.inboxIds,
    timezoneOffset: new Date().getTimezoneOffset() * -60,
  });
};

const onFiltersChange = payload => {
  filters.value = {
    ...filters.value,
    ...payload,
  };
};

const onTimelineChange = payload => {
  filters.value = {
    ...filters.value,
    since: payload.since,
    until: payload.until,
  };
};

watch(filters, fetch, { deep: true, immediate: true });
</script>

<template>
  <ReportHeader
    :header-title="t('AGENT_ACTIVITY_REPORTS.HEADER')"
    :header-description="t('AGENT_ACTIVITY_REPORTS.DESCRIPTION')"
  >
    <V4Button
      :label="t('AGENT_ACTIVITY_REPORTS.CSV_DOWNLOAD')"
      icon="i-ph-download-simple"
      size="sm"
      @click="onDownloadClick"
    />
  </ReportHeader>

  <div class="flex flex-col gap-4">
    <AgentActivityFilters
      :initial-since="filters.since"
      :initial-until="filters.until"
      :initial-hide-inactive="filters.hideInactive"
      @filters-change="onFiltersChange"
    />

    <AgentActivityTimeline
      :filters="filters"
      @timeline-change="onTimelineChange"
    />
  </div>
</template>
