<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import subDays from 'date-fns/subDays';
import differenceInDays from 'date-fns/differenceInDays';
import ActiveFilterChip from './Filters/v3/ActiveFilterChip.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import { GROUP_BY_FILTER } from '../constants';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';
import {
  generateReportURLParams,
  parseReportURLParams,
} from '../helpers/reportFilterHelper';

const props = defineProps({
  filterType: {
    type: String,
    required: false,
    default: '',
    validator: value =>
      ['teams', 'inboxes', 'labels', 'agents', ''].includes(value),
  },
  selectedItem: {
    type: Object,
    default: null,
  },
  showGroupBy: {
    type: Boolean,
    default: true,
  },
  showBusinessHours: {
    type: Boolean,
    default: true,
  },
  showEntityFilter: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['filterChange']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const buildReportFilterList = (items, type) => {
  if (!Array.isArray(items)) return [];

  return items.map(item => ({
    id: item.id,
    name: item.name || item.title,
    type,
  }));
};

const getReportFilterKey = filterType => {
  const keyMap = {
    teams: 'team_id',
    inboxes: 'inbox_id',
    labels: 'label_id',
    agents: 'agent_id',
  };
  return keyMap[filterType] || '';
};

const getFilterKey = () => getReportFilterKey(props.filterType);

const showSubDropdownMenu = ref(false);
const showGroupByDropdown = ref(false);
const activeFilterType = ref('');
const customDateRange = ref([subDays(new Date(), 6), new Date()]);
const selectedDateRange = ref(DATE_RANGE_TYPES.LAST_7_DAYS);
const businessHoursSelected = ref(false);
const groupBy = ref(GROUP_BY_FILTER[1]);
const groupByfilterItemsList = ref([{ id: 1, name: 'Day' }]);

const appliedFilters = ref(
  props.showEntityFilter
    ? { [getFilterKey()]: props.selectedItem?.id || null }
    : {}
);

const filterSource = computed(() => {
  const sources = {
    teams: store.getters['teams/getTeams'],
    inboxes: store.getters['inboxes/getInboxes'],
    labels: store.getters['labels/getLabels'],
    agents: store.getters['agents/getAgents'],
  };
  return sources[props.filterType] || [];
});

const from = computed(() => getUnixStartOfDay(customDateRange.value[0]));
const to = computed(() => getUnixEndOfDay(customDateRange.value[1]));

const daysDifference = computed(() => {
  return differenceInDays(customDateRange.value[1], customDateRange.value[0]);
});

const isGroupByPossible = computed(() => {
  return props.showGroupBy && daysDifference.value >= 29;
});

const GROUP_BY_OPTIONS = computed(() => ({
  WEEK: [
    { id: 1, name: t('REPORT.GROUPING_OPTIONS.DAY') },
    { id: 2, name: t('REPORT.GROUPING_OPTIONS.WEEK') },
  ],
  MONTH: [
    { id: 1, name: t('REPORT.GROUPING_OPTIONS.DAY') },
    { id: 2, name: t('REPORT.GROUPING_OPTIONS.WEEK') },
    { id: 3, name: t('REPORT.GROUPING_OPTIONS.MONTH') },
  ],
  YEAR: [
    { id: 2, name: t('REPORT.GROUPING_OPTIONS.WEEK') },
    { id: 3, name: t('REPORT.GROUPING_OPTIONS.MONTH') },
    { id: 4, name: t('REPORT.GROUPING_OPTIONS.YEAR') },
  ],
}));

const fetchFilterItems = () => {
  const days = daysDifference.value;
  if (days >= 364) return GROUP_BY_OPTIONS.value.YEAR;
  if (days >= 90) return GROUP_BY_OPTIONS.value.MONTH;
  if (days >= 29) return GROUP_BY_OPTIONS.value.WEEK;
  return GROUP_BY_OPTIONS.value.WEEK;
};

const filterOptions = computed(() =>
  buildReportFilterList(filterSource.value, props.filterType)
);

const filterPlaceholder = computed(() => {
  const placeholders = {
    teams: 'TEAM_REPORTS.FILTERS.INPUT_PLACEHOLDER.TEAMS',
    inboxes: 'INBOX_REPORTS.FILTERS.INPUT_PLACEHOLDER.INBOXES',
    labels: 'LABEL_REPORTS.FILTERS.INPUT_PLACEHOLDER.LABELS',
    agents: 'AGENT_REPORTS.FILTERS.INPUT_PLACEHOLDER.AGENTS',
  };
  return t(placeholders[props.filterType] || '');
});

const defaultFilterLabel = computed(() => {
  const labelKeys = {
    teams: 'TEAM_REPORTS.FILTER_DROPDOWN_LABEL',
    inboxes: 'INBOX_REPORTS.FILTER_DROPDOWN_LABEL',
    labels: 'LABEL_REPORTS.FILTER_DROPDOWN_LABEL',
    agents: 'AGENT_REPORTS.FILTER_DROPDOWN_LABEL',
  };
  return t(labelKeys[props.filterType] || 'FORMS.MULTISELECT.SELECT_ONE');
});

const selectedFilterName = computed(() => {
  const filterKey = getFilterKey();
  const selectedId = appliedFilters.value[filterKey];

  if (!selectedId) {
    return defaultFilterLabel.value;
  }

  const selectedItem = filterOptions.value.find(item => item.id === selectedId);
  return selectedItem?.name || defaultFilterLabel.value;
});

const updateURLParams = () => {
  const params = generateReportURLParams({
    from: from.value,
    to: to.value,
    businessHours: businessHoursSelected.value,
    groupBy: isGroupByPossible.value ? groupBy.value.id : null,
    range: selectedDateRange.value,
  });

  router.replace({ query: { ...params } });
};

const emitChange = () => {
  const payload = {
    from: from.value,
    to: to.value,
    businessHours: businessHoursSelected.value,
  };

  if (props.showGroupBy) {
    // Always emit groupBy, default to day when range is too short
    payload.groupBy = isGroupByPossible.value
      ? groupBy.value
      : GROUP_BY_FILTER[1];
  }

  if (props.showEntityFilter) {
    const filterKey = getFilterKey();
    const selectedValue = appliedFilters.value[filterKey];

    if (selectedValue) {
      payload[props.filterType] =
        props.filterType === 'agents'
          ? [{ id: selectedValue }]
          : { id: selectedValue };
    }
  }

  updateURLParams();
  emit('filterChange', payload);
};

const closeActiveFilterDropdown = () => {
  showSubDropdownMenu.value = false;
  activeFilterType.value = '';
};

const openActiveFilterDropdown = filterType => {
  showGroupByDropdown.value = false;
  activeFilterType.value = filterType;
  showSubDropdownMenu.value = !showSubDropdownMenu.value;
};

const addFilter = item => {
  const filterKey = getFilterKey();
  appliedFilters.value[filterKey] = item.id;
  closeActiveFilterDropdown();
  emitChange();

  // Navigate to the new entity's route
  const routeNameMap = {
    teams: 'team_reports_show',
    inboxes: 'inbox_reports_show',
    labels: 'label_reports_show',
    agents: 'agent_reports_show',
  };

  const routeName = routeNameMap[props.filterType];
  if (routeName) {
    router.push({
      name: routeName,
      params: { ...route.params, id: item.id },
      query: route.query,
    });
  }
};

const onDateRangeChange = value => {
  const [startDate, endDate, rangeType] = value;
  customDateRange.value = [startDate, endDate];
  selectedDateRange.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  groupByfilterItemsList.value = fetchFilterItems();
  const filterItems = groupByfilterItemsList.value.filter(
    item => item.id === groupBy.value.id
  );
  if (filterItems.length === 0) {
    groupBy.value = GROUP_BY_FILTER[groupByfilterItemsList.value[0].id];
  }
  emitChange();
};

const onBusinessHoursToggle = () => {
  emitChange();
};

const onGroupByFilterChange = payload => {
  groupBy.value = GROUP_BY_FILTER[payload.id];
  showGroupByDropdown.value = false;
  emitChange();
};

const toggleGroupByDropdown = () => {
  showGroupByDropdown.value = !showGroupByDropdown.value;
};

const closeGroupByDropdown = () => {
  showGroupByDropdown.value = false;
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

  if (urlParams.groupBy) {
    const groupByValue = GROUP_BY_FILTER[urlParams.groupBy];
    if (groupByValue) {
      groupBy.value = groupByValue;
    }
  }

  // Initialize entity filter from route params (not URL query)
  if (props.showEntityFilter && route.params.id) {
    const filterKey = getFilterKey();
    appliedFilters.value[filterKey] = Number(route.params.id);
  }
};

onMounted(() => {
  initializeFromURL();
  groupByfilterItemsList.value = fetchFilterItems();
  emitChange();
});
</script>

<template>
  <div class="flex flex-col w-full gap-3 lg:flex-row">
    <WootDatePicker
      v-model:date-range="customDateRange"
      v-model:range-type="selectedDateRange"
      @date-range-changed="onDateRangeChange"
    />

    <div class="flex gap-2 items-center w-full">
      <ActiveFilterChip
        v-if="showEntityFilter"
        :id="appliedFilters[getFilterKey()]"
        :name="selectedFilterName"
        :type="filterType"
        :options="filterOptions"
        :active-filter-type="activeFilterType"
        :show-menu="showSubDropdownMenu"
        :placeholder="filterPlaceholder"
        :show-clear-filter="false"
        enable-search
        @toggle-dropdown="openActiveFilterDropdown"
        @close-dropdown="closeActiveFilterDropdown"
        @add-filter="addFilter"
      />

      <ActiveFilterChip
        v-if="isGroupByPossible"
        :id="groupBy?.id"
        :name="
          groupByfilterItemsList.find(item => item.id === groupBy?.id)?.name ||
          $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')
        "
        type="groupBy"
        :options="groupByfilterItemsList"
        :active-filter-type="showGroupByDropdown ? 'groupBy' : ''"
        :show-menu="showGroupByDropdown"
        :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
        :enable-search="false"
        :show-clear-filter="false"
        @toggle-dropdown="toggleGroupByDropdown"
        @close-dropdown="closeGroupByDropdown"
        @add-filter="onGroupByFilterChange"
        @remove-filter="() => {}"
      />

      <div
        v-if="showBusinessHours"
        class="flex items-center flex-shrink-0 ltr:ml-auto rtl:mr-auto"
      >
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
  </div>
</template>
