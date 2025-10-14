<script setup>
import { onMounted, ref, computed } from 'vue';
import { useToggle } from '@vueuse/core';
import MetricCard from '../overview/MetricCard.vue';
import BaseHeatmap from './BaseHeatmap.vue';
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

const props = defineProps({
  metric: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  downloadTitle: {
    type: String,
    required: true,
  },
  storeGetter: {
    type: String,
    required: true,
  },
  storeAction: {
    type: String,
    required: true,
  },
  downloadAction: {
    type: String,
    default: '',
  },
  uiFlagKey: {
    type: String,
    required: true,
  },
  colorScheme: {
    type: String,
    default: 'blue',
  },
});

const store = useStore();
const { t } = useI18n();

const uiFlags = useMapGetter('getOverviewUIFlags');
const heatmapData = useMapGetter(props.storeGetter);
const inboxes = useMapGetter('inboxes/getInboxes');

const menuItems = [
  {
    label: t('REPORT.DATE_RANGE_OPTIONS.LAST_7_DAYS'),
    value: 6,
  },
  {
    label: t('REPORT.DATE_RANGE_OPTIONS.LAST_14_DAYS'),
    value: 13,
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
      action: 'select_inbox',
    },
    ...inboxes.value.map(inbox => ({
      label: inbox.name,
      value: inbox.id,
      action: 'select_inbox',
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

const isLoading = computed(() => uiFlags.value[props.uiFlagKey]);

const downloadHeatmapData = () => {
  const to = endOfDay(new Date());

  // If no inbox is selected and download action exists, use backend endpoint
  if (!selectedInbox.value && props.downloadAction) {
    store.dispatch(props.downloadAction, {
      daysBefore: selectedDays.value,
      to: getUnixTime(to),
    });
    return;
  }

  // Generate CSV from store data
  if (!heatmapData.value || heatmapData.value.length === 0) {
    return;
  }

  // Create CSV headers
  const headers = ['Date', 'Hour', props.title];
  const rows = [headers];

  // Convert heatmap data to rows
  heatmapData.value.forEach(item => {
    const date = new Date(item.timestamp * 1000);
    const dateStr = format(date, 'yyyy-MM-dd');
    const hour = date.getHours();
    rows.push([dateStr, `${hour}:00 - ${hour + 1}:00`, item.value]);
  });

  // Convert to CSV string
  const csvContent = rows.map(row => row.join(',')).join('\n');

  // Generate filename
  const inboxName = selectedInbox.value
    ? `_${selectedInbox.value.name.replace(/[^a-z0-9]/gi, '_')}`
    : '';
  const fileName = `${props.downloadTitle}${inboxName}_${format(
    new Date(),
    'dd-MM-yyyy'
  )}.csv`;

  // Download the file
  downloadCsvFile(fileName, csvContent);
};

const [showDropdown, toggleDropdown] = useToggle();
const [showInboxDropdown, toggleInboxDropdown] = useToggle();

const fetchHeatmapData = () => {
  if (isLoading.value) {
    return;
  }

  let to = endOfDay(new Date());
  let from = startOfDay(subDays(to, Number(selectedDays.value)));

  const params = {
    metric: props.metric,
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

  store.dispatch(props.storeAction, params);
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
    <MetricCard :header="title">
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
      <BaseHeatmap
        :heatmap-data="heatmapData"
        :number-of-rows="selectedDays + 1"
        :is-loading="isLoading"
        :color-scheme="colorScheme"
      />
    </MetricCard>
  </div>
</template>
