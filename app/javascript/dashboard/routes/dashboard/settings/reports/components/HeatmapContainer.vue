<script setup>
import { onMounted, ref, computed } from 'vue';
import { useToggle } from '@vueuse/core';
import MetricCard from './overview/MetricCard.vue';
import ReportHeatmap from './Heatmap.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import endOfDay from 'date-fns/endOfDay';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import subDays from 'date-fns/subDays';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';

const store = useStore();

const uiFlags = useMapGetter('getOverviewUIFlags');
const accountConversationHeatmap = useMapGetter(
  'getAccountConversationHeatmapData'
);
const { t } = useI18n();

const menuItems = [
  {
    label: t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS'),
    value: 6,
  },
  {
    label: t('REPORT.DATE_RANGE_OPTIONS.LAST_30_DAYS'),
    value: 29,
  },
];

const selectedDays = ref(6);

const selectedDayFilter = computed(() =>
  menuItems.find(menuItem => menuItem.value === selectedDays.value)
);

const downloadHeatmapData = () => {
  const to = endOfDay(new Date());
  store.dispatch('downloadAccountConversationHeatmap', {
    daysBefore: selectedDays.value,
    to: getUnixTime(to),
  });
};
const [showDropdown, toggleDropdown] = useToggle();
const fetchHeatmapData = () => {
  if (uiFlags.value.isFetchingAccountConversationsHeatmap) {
    return;
  }

  let to = endOfDay(new Date());
  let from = startOfDay(subDays(to, Number(selectedDays.value)));

  store.dispatch('fetchAccountConversationHeatmap', {
    metric: 'conversations_count',
    from: getUnixTime(from),
    to: getUnixTime(to),
    groupBy: 'hour',
    businessHours: false,
  });
};

const handleAction = ({ value }) => {
  toggleDropdown(false);
  selectedDays.value = value;
  fetchHeatmapData();
};

const { startRefetching } = useLiveRefresh(fetchHeatmapData);

onMounted(() => {
  fetchHeatmapData();
  startRefetching();
});
</script>

<template>
  <div class="flex flex-row flex-wrap max-w-full">
    <MetricCard :header="$t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.HEADER')">
      <template #control>
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
        >
          <Button
            sm
            slate
            faded
            :label="selectedDayFilter.label"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showDropdown"
            :menu-items="menuItems"
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </div>
        <Button
          sm
          slate
          faded
          :label="t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.DOWNLOAD_REPORT')"
          class="rounded-md group-hover:bg-n-alpha-2"
          @click="downloadHeatmapData"
        />
      </template>
      <ReportHeatmap
        :heatmap-data="accountConversationHeatmap"
        :number-of-rows="selectedDays + 1"
        :is-loading="uiFlags.isFetchingAccountConversationsHeatmap"
      />
    </MetricCard>
  </div>
</template>
