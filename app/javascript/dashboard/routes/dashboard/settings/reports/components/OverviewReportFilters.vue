<script setup>
import { computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import subDays from 'date-fns/subDays';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import ActiveFilterChip from './Filters/v3/ActiveFilterChip.vue';
import {
  generateReportURLParams,
  parseReportURLParams,
  generateFilterURLParams,
  parseFilterURLParams,
} from '../helpers/reportFilterHelper';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';

const props = defineProps({
  disabled: {
    type: Boolean,
    default: false,
  },
  // Second dimension the report can be narrowed to: an agents overview reads for
  // a single inbox, an inboxes overview reads for a single agent.
  crossFilterType: {
    type: String,
    default: '',
    validator: value => ['', 'inboxes', 'agents'].includes(value),
  },
});

const emit = defineEmits(['filterChange']);

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const customDateRange = ref([subDays(new Date(), 6), new Date()]);
const selectedDateRange = ref(DATE_RANGE_TYPES.LAST_7_DAYS);
const businessHoursSelected = ref(false);
const crossFilterId = ref(null);
const showCrossFilterMenu = ref(false);

const CROSS_FILTER_CONFIG = {
  inboxes: {
    urlKey: 'inbox_id',
    payloadKey: 'inboxId',
    getterKey: 'inboxes/getInboxes',
    fetchKey: 'inboxes/get',
    allLabelKey: 'REPORT.CROSS_FILTER.ALL_INBOXES',
    placeholderKey: 'INBOX_REPORTS.FILTERS.INPUT_PLACEHOLDER.INBOXES',
  },
  agents: {
    urlKey: 'agent_id',
    payloadKey: 'userId',
    getterKey: 'agents/getAgents',
    fetchKey: 'agents/get',
    allLabelKey: 'REPORT.CROSS_FILTER.ALL_AGENTS',
    placeholderKey: 'AGENT_REPORTS.FILTERS.INPUT_PLACEHOLDER.AGENTS',
  },
};

const crossFilterConfig = computed(
  () => CROSS_FILTER_CONFIG[props.crossFilterType] ?? null
);

const crossFilterOptions = computed(() => {
  if (!crossFilterConfig.value) return [];

  const items = store.getters[crossFilterConfig.value.getterKey] ?? [];
  return items.map(item => ({
    id: item.id,
    name: item.name,
    type: props.crossFilterType,
  }));
});

const crossFilterName = computed(() => {
  if (!crossFilterConfig.value) return '';
  if (!crossFilterId.value) return t(crossFilterConfig.value.allLabelKey);

  const selected = crossFilterOptions.value.find(
    item => item.id === crossFilterId.value
  );
  // The "All" label belongs to a cleared filter and to nothing else. A bookmarked
  // URL applies the id before its list arrives, and the id can name something this
  // user cannot list at all, so falling back to it here would leave the chip
  // claiming the opposite of the request that was actually sent.
  return selected?.name ?? `#${crossFilterId.value}`;
});

const crossFilterPayload = computed(() => {
  if (!crossFilterConfig.value) return {};

  return { [crossFilterConfig.value.payloadKey]: crossFilterId.value };
});

const updateURLParams = () => {
  const params = generateReportURLParams({
    from: getUnixStartOfDay(customDateRange.value[0]),
    to: getUnixEndOfDay(customDateRange.value[1]),
    businessHours: businessHoursSelected.value,
    range: selectedDateRange.value,
  });

  const filterParams = crossFilterConfig.value
    ? generateFilterURLParams({
        [crossFilterConfig.value.urlKey]: crossFilterId.value,
      })
    : {};

  router.replace({ query: { ...params, ...filterParams } });
};

const emitChange = () => {
  updateURLParams();
  emit('filterChange', {
    from: getUnixStartOfDay(customDateRange.value[0]),
    to: getUnixEndOfDay(customDateRange.value[1]),
    businessHours: businessHoursSelected.value,
    ...crossFilterPayload.value,
  });
};

const onDateRangeChange = value => {
  const [startDate, endDate, rangeType] = value;
  customDateRange.value = [startDate, endDate];
  selectedDateRange.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  emitChange();
};

const onBusinessHoursToggle = () => {
  emitChange();
};

const toggleCrossFilterDropdown = () => {
  showCrossFilterMenu.value = !showCrossFilterMenu.value;
};

const closeCrossFilterDropdown = () => {
  showCrossFilterMenu.value = false;
};

const onCrossFilterSelect = item => {
  crossFilterId.value = item.id;
  closeCrossFilterDropdown();
  emitChange();
};

const onCrossFilterRemove = () => {
  crossFilterId.value = null;
  closeCrossFilterDropdown();
  emitChange();
};

const initializeFromURL = () => {
  const urlParams = parseReportURLParams(route.query);

  // Set the range type first
  if (urlParams.range) {
    selectedDateRange.value = urlParams.range;
  }

  // Restore dates from URL if available
  if (urlParams.from && urlParams.to) {
    customDateRange.value = [
      new Date(urlParams.from * 1000),
      new Date(urlParams.to * 1000),
    ];
  }

  if (urlParams.businessHours) {
    businessHoursSelected.value = urlParams.businessHours;
  }

  if (crossFilterConfig.value) {
    crossFilterId.value = parseFilterURLParams(route.query)[
      crossFilterConfig.value.urlKey
    ];
  }
};

onMounted(() => {
  if (crossFilterConfig.value) {
    store.dispatch(crossFilterConfig.value.fetchKey);
  }
  initializeFromURL();
  emitChange();
});
</script>

<template>
  <div
    class="flex flex-col justify-between gap-3 md:flex-row"
    :class="{ 'pointer-events-none opacity-50': disabled }"
  >
    <div class="flex flex-col flex-wrap items-start gap-2 md:flex-row">
      <WootDatePicker
        v-model:date-range="customDateRange"
        v-model:range-type="selectedDateRange"
        @date-range-changed="onDateRangeChange"
      />
      <ActiveFilterChip
        v-if="crossFilterConfig"
        :id="crossFilterId"
        :name="crossFilterName"
        :type="crossFilterType"
        :options="crossFilterOptions"
        :active-filter-type="showCrossFilterMenu ? crossFilterType : ''"
        :show-menu="showCrossFilterMenu"
        :placeholder="$t(crossFilterConfig.placeholderKey)"
        enable-search
        @toggle-dropdown="toggleCrossFilterDropdown"
        @close-dropdown="closeCrossFilterDropdown"
        @add-filter="onCrossFilterSelect"
        @remove-filter="onCrossFilterRemove"
      />
    </div>
    <div class="flex items-center">
      <span class="mx-2 text-sm whitespace-nowrap">
        {{ $t('REPORT.BUSINESS_HOURS') }}
      </span>
      <span>
        <ToggleSwitch
          v-model="businessHoursSelected"
          @change="onBusinessHoursToggle"
        />
      </span>
    </div>
  </div>
</template>
