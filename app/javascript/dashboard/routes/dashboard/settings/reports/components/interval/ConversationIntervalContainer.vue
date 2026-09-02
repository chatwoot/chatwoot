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
import IntervalTable from './IntervalTable.vue';

const store = useStore();
const { t } = useI18n();

const uiFlags = useMapGetter('getOverviewUIFlags');
const intervalData = useMapGetter('getAccountConversationIntervalData');

const selectedFrom = ref(null);
const selectedTo = ref(null);
const selectedDaysBefore = ref(null);
const isMonthFilter = ref(false);
const currentMonthOffset = ref(0);

const selectedRange = computed(() => {
  if (!selectedFrom.value || !selectedTo.value) {
    return null;
  }

  return {
    from: selectedFrom.value,
    to: selectedTo.value,
  };
});

const isLoading = computed(
  () => uiFlags.value.isFetchingAccountConversationInterval
);

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

const fetchIntervalData = () => {
  if (isLoading.value) {
    return;
  }

  const range = resolveActiveRange();
  if (!range) {
    return;
  }

  const { from, to } = range;
  store.dispatch('fetchAccountConversationInterval', {
    metric: 'conversations_count',
    from: getUnixTime(from),
    to: getUnixTime(to),
    groupBy: 'hour',
    businessHours: false,
  });
};

const { startRefetching } = useLiveRefresh(fetchIntervalData);

const handleRangeTypeChange = type => {
  isMonthFilter.value = type === 'month';
};

const handleMonthOffsetChange = offset => {
  currentMonthOffset.value = offset;
};

watch(
  () => [selectedFrom.value, selectedTo.value],
  ([from, to]) => {
    if (from && to) {
      fetchIntervalData();
    }
  }
);

onMounted(() => {
  startRefetching();
});
</script>

<template>
  <div class="flex max-w-full flex-row flex-wrap">
    <MetricCard
      :header="t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.HEADER')"
      :is-loading="isLoading"
      :loading-message="
        t('OVERVIEW_REPORTS.CONVERSATION_INTERVAL.LOADING_MESSAGE')
      "
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
      <IntervalTable :interval-data="intervalData" />
    </MetricCard>
  </div>
</template>
