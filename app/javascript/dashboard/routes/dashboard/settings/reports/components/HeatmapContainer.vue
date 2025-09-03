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
import format from 'date-fns/format';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useI18n } from 'vue-i18n';
import { downloadCsvFile } from 'dashboard/helper/downloadHelper';

const store = useStore();

const uiFlags = useMapGetter('getOverviewUIFlags');
const accountConversationHeatmap = useMapGetter(
  'getAccountConversationHeatmapData'
);
const inboxes = useMapGetter('inboxes/getInboxes');
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
const selectedInbox = ref(null);

const selectedDayFilter = computed(() =>
  menuItems.find(menuItem => menuItem.value === selectedDays.value)
);

const inboxMenuItems = computed(() => {
  return [
    {
      label: t('INBOX_REPORTS.ALL_INBOXES'),
      value: null,
    },
    ...inboxes.value.map(inbox => ({
      label: inbox.name,
      value: inbox.id,
    })),
  ];
});

const selectedInboxFilter = computed(() => {
  if (!selectedInbox.value) {
    return { label: t('INBOX_REPORTS.ALL_INBOXES') };
  }
  return inboxMenuItems.value.find(
    item => item.value === selectedInbox.value.id
  );
});

const downloadHeatmapData = () => {
  const to = endOfDay(new Date());

  // If no inbox is selected, use the existing backend CSV endpoint
  if (!selectedInbox.value) {
    store.dispatch('downloadAccountConversationHeatmap', {
      daysBefore: selectedDays.value,
      to: getUnixTime(to),
    });
    return;
  }

  // If inbox is selected, generate CSV from store data
  if (
    !accountConversationHeatmap.value ||
    accountConversationHeatmap.value.length === 0
  ) {
    return;
  }

  // Create CSV headers
  const headers = ['Date', 'Hour', 'Conversations Count'];
  const rows = [headers];

  // Convert heatmap data to rows
  accountConversationHeatmap.value.forEach(item => {
    const date = new Date(item.timestamp * 1000);
    const dateStr = format(date, 'yyyy-MM-dd');
    const hour = date.getHours();
    rows.push([dateStr, `${hour}:00 - ${hour + 1}:00`, item.value]);
  });

  // Convert to CSV string
  const csvContent = rows.map(row => row.join(',')).join('\n');

  // Generate filename with inbox name
  const inboxName = selectedInbox.value.name.replace(/[^a-z0-9]/gi, '_');
  const fileName = `conversation_heatmap_${inboxName}_${format(new Date(), 'dd-MM-yyyy')}.csv`;

  // Download the file
  downloadCsvFile(fileName, csvContent);
};
const [showDropdown, toggleDropdown] = useToggle();
const [showInboxDropdown, toggleInboxDropdown] = useToggle();
const fetchHeatmapData = () => {
  if (uiFlags.value.isFetchingAccountConversationsHeatmap) {
    return;
  }

  let to = endOfDay(new Date());
  let from = startOfDay(subDays(to, Number(selectedDays.value)));

  const params = {
    metric: 'conversations_count',
    from: getUnixTime(from),
    to: getUnixTime(to),
    groupBy: 'hour',
    businessHours: false,
  };

  // Add inbox filtering if an inbox is selected
  if (selectedInbox.value) {
    params.type = 'inbox';
    params.id = selectedInbox.value.id;
  }

  store.dispatch('fetchAccountConversationHeatmap', params);
};

const handleAction = ({ value }) => {
  toggleDropdown(false);
  selectedDays.value = value;
  fetchHeatmapData();
};

const handleInboxAction = ({ value }) => {
  toggleInboxDropdown(false);
  selectedInbox.value = value
    ? inboxes.value.find(inbox => inbox.id === value)
    : null;
  fetchHeatmapData();
};

const { startRefetching } = useLiveRefresh(fetchHeatmapData);

onMounted(() => {
  store.dispatch('inboxes/get');
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
        <div
          v-on-clickaway="() => toggleInboxDropdown(false)"
          class="relative flex items-center group"
        >
          <Button
            sm
            slate
            faded
            :label="selectedInboxFilter.label"
            class="rounded-md group-hover:bg-n-alpha-2 max-w-[200px]"
            @click="toggleInboxDropdown()"
          />
          <DropdownMenu
            v-if="showInboxDropdown"
            :menu-items="inboxMenuItems"
            show-search
            :search-placeholder="t('INBOX_REPORTS.SEARCH_INBOX')"
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full min-w-[200px]"
            @action="handleInboxAction($event)"
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
