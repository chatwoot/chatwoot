<script setup>
import { onMounted, ref, computed, watch } from 'vue';
import { useToggle } from '@vueuse/core';
import MetricCard from '../overview/MetricCard.vue';
import BaseHeatmap from './BaseHeatmap.vue';
import HeatmapDateRangeSelector from './HeatmapDateRangeSelector.vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useLiveRefresh } from 'dashboard/composables/useLiveRefresh';
import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';
import endOfDay from 'date-fns/endOfDay';
import format from 'date-fns/format';
import getUnixTime from 'date-fns/getUnixTime';
import startOfDay from 'date-fns/startOfDay';
import startOfMonth from 'date-fns/startOfMonth';
import subDays from 'date-fns/subDays';
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

const selectedFrom = ref(null);
const selectedTo = ref(null);
const selectedDaysBefore = ref(null);
const selectedInbox = ref(null);
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

const numberOfRows = computed(() => {
  if (!selectedRange.value) {
    return 0;
  }
  const dateDifference = differenceInCalendarDays(
    selectedRange.value.to,
    selectedRange.value.from
  );
  return dateDifference + 1;
});

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

const downloadHeatmapData = () => {
  const range = resolveActiveRange();
  if (!range) {
    return;
  }

  const { to } = range;
  const shouldUseBackendDownload =
    !isMonthFilter.value && !selectedInbox.value && props.downloadAction;

  // If no inbox is selected and download action exists, use backend endpoint
  if (shouldUseBackendDownload) {
    store.dispatch(props.downloadAction, {
      daysBefore: selectedDaysBefore.value,
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

const [showInboxDropdown, toggleInboxDropdown] = useToggle();

const fetchHeatmapData = () => {
  if (isLoading.value) {
    return;
  }

  const range = resolveActiveRange();
  if (!range) {
    return;
  }

  const { from, to } = range;

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

const handleInboxAction = ({ value }) => {
  toggleInboxDropdown(false);
  selectedInbox.value = value
    ? inboxes.value.find(inbox => inbox.id === value)
    : null;
};

const { startRefetching } = useLiveRefresh(fetchHeatmapData);

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
      fetchHeatmapData();
    }
  }
);

watch(
  () => selectedInbox.value,
  () => {
    if (selectedRange.value) {
      fetchHeatmapData();
    }
  }
);

onMounted(() => {
  store.dispatch('inboxes/get');
  startRefetching();
});
</script>

<template>
  <div class="flex flex-row flex-wrap max-w-full">
    <MetricCard :header="title">
      <template #control>
        <HeatmapDateRangeSelector
          v-model:from="selectedFrom"
          v-model:to="selectedTo"
          v-model:days-num="selectedDaysBefore"
          @range-type-change="handleRangeTypeChange"
          @month-offset-change="handleMonthOffsetChange"
        />
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
            class="mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0 top-full !min-w-56 max-w-56 max-h-96 overflow-y-auto"
            @action="handleInboxAction($event)"
          />
        </div>
        <Button
          v-tooltip="t('OVERVIEW_REPORTS.CONVERSATION_HEATMAP.DOWNLOAD_REPORT')"
          sm
          slate
          faded
          icon="i-lucide-download"
          class="rounded-md group-hover:bg-n-alpha-2"
          @click="downloadHeatmapData"
        />
      </template>
      <BaseHeatmap
        :heatmap-data="heatmapData"
        :number-of-rows="numberOfRows"
        :is-loading="isLoading"
        :color-scheme="colorScheme"
      />
    </MetricCard>
  </div>
</template>
