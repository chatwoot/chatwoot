<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import startOfMonth from 'date-fns/startOfMonth';
import subDays from 'date-fns/subDays';

import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import HeatmapDateRangeSelector from '../heatmaps/HeatmapDateRangeSelector.vue';
import MetricCard from '../overview/MetricCard.vue';
import AgentRankingTable from './AgentRankingTable.vue';

const store = useStore();
const { t } = useI18n();

const agents = useMapGetter('agents/getAgents');
const summaryReports = useMapGetter('summaryReports/getAgentSummaryReports');
const uiFlags = useMapGetter('summaryReports/getUIFlags');

const selectedFrom = ref(null);
const selectedTo = ref(null);
const selectedDaysBefore = ref(null);
const isMonthFilter = ref(false);
const currentMonthOffset = ref(0);
const isMounted = ref(false);

const selectedRange = computed(() => {
  if (!selectedFrom.value || !selectedTo.value) {
    return null;
  }

  return {
    from: selectedFrom.value,
    to: selectedTo.value,
  };
});

const isLoading = computed(() => uiFlags.value.isFetchingAgentSummaryReports);

const rows = computed(() => {
  const metricsByAgentId = new Map(
    summaryReports.value.map(metrics => [Number(metrics.id), metrics])
  );

  return agents.value
    .map(agent => {
      const metrics = metricsByAgentId.get(Number(agent.id)) || {};
      return {
        id: agent.id,
        name: agent.name,
        conversationsCount: metrics.conversationsCount ?? 0,
        resolvedCount: metrics.resolvedConversationsCount ?? 0,
      };
    })
    .sort(
      (first, second) =>
        second.resolvedCount - first.resolvedCount ||
        second.conversationsCount - first.conversationsCount ||
        first.name.localeCompare(second.name)
    );
});

// Keeps relative presets (last 7 days / this month) aligned with "now" during live refreshes.
const resolveActiveRange = () => {
  if (isMonthFilter.value && currentMonthOffset.value === 0) {
    const now = new Date();
    const monthStart = startOfMonth(now);
    return {
      from: startOfDay(monthStart),
      to: endOfDay(now),
    };
  }

  if (!isMonthFilter.value && selectedDaysBefore.value !== null) {
    const to = endOfDay(new Date());
    return {
      from: startOfDay(subDays(to, Number(selectedDaysBefore.value))),
      to,
    };
  }

  return selectedRange.value;
};

const fetchRankingData = async () => {
  if (isLoading.value) {
    return;
  }

  const range = resolveActiveRange();
  if (!range) {
    return;
  }

  const { from, to } = range;
  try {
    await store.dispatch('summaryReports/fetchAgentSummaryReports', {
      since: getUnixTime(from),
      until: getUnixTime(to),
      businessHours: false,
    });
  } catch {
    // Overview cards keep rendering their last data after transient refresh failures.
  }
};

const { startRefetching } = useLiveRefresh(fetchRankingData);

const handleRangeTypeChange = type => {
  isMonthFilter.value = type === 'month';
};

const handleMonthOffsetChange = offset => {
  currentMonthOffset.value = offset;
};

watch(
  () => [selectedFrom.value, selectedTo.value],
  ([from, to]) => {
    if (isMounted.value && from && to) {
      fetchRankingData();
    }
  }
);

onMounted(async () => {
  await store.dispatch('agents/get');
  isMounted.value = true;
  await fetchRankingData();
  startRefetching();
});
</script>

<template>
  <div class="flex max-w-full flex-row flex-wrap">
    <MetricCard
      :header="t('OVERVIEW_REPORTS.AGENT_RANKING.HEADER')"
      :is-loading="isLoading"
      :loading-message="t('OVERVIEW_REPORTS.AGENT_RANKING.LOADING_MESSAGE')"
    >
      <template #control>
        <HeatmapDateRangeSelector
          v-model:from="selectedFrom"
          v-model:to="selectedTo"
          v-model:days-num="selectedDaysBefore"
          @range-type-change="handleRangeTypeChange"
          @month-offset-change="handleMonthOffsetChange"
        />
      </template>
      <AgentRankingTable :rows="rows" />
    </MetricCard>
  </div>
</template>
