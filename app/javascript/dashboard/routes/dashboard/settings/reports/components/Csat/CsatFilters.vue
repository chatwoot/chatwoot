<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { subDays, fromUnixTime } from 'date-fns';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import {
  buildFilterList,
  buildRatingsList,
  getActiveFilter,
  getFilterType,
} from './CsatFilterHelpers';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import ActiveFilterChip from '../Filters/v3/ActiveFilterChip.vue';
import AddFilterChip from '../Filters/v3/AddFilterChip.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import {
  parseReportURLParams,
  parseFilterURLParams,
  generateCompleteURLParams,
} from '../../helpers/reportFilterHelper';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';

const props = defineProps({
  showTeamFilter: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['filterChange']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

// Initialize from URL params immediately
const urlParams = parseReportURLParams(route.query);
const urlFilters = parseFilterURLParams(route.query);

const initialDateRange =
  urlParams.from && urlParams.to
    ? [fromUnixTime(urlParams.from), fromUnixTime(urlParams.to)]
    : [subDays(new Date(), 6), new Date()];

const showDropdownMenu = ref(false);
const showSubDropdownMenu = ref(false);
const activeFilterType = ref('');
const customDateRange = ref(initialDateRange);
const selectedDateRange = ref(urlParams.range || DATE_RANGE_TYPES.LAST_7_DAYS);

const appliedFilters = ref({
  user_ids: urlFilters.agent_id,
  inbox_id: urlFilters.inbox_id,
  team_id: urlFilters.team_id,
  rating: urlFilters.rating,
});

const agents = computed(() => store.getters['agents/getAgents']);
const inboxes = computed(() => store.getters['inboxes/getInboxes']);
const teams = computed(() => store.getters['teams/getTeams']);

const ratings = computed(() => buildRatingsList(t));

const from = computed(() => getUnixStartOfDay(customDateRange.value[0]));
const to = computed(() => getUnixEndOfDay(customDateRange.value[1]));

const getFilterSource = type => {
  const sources = {
    agents: agents.value,
    inboxes: inboxes.value,
    teams: teams.value,
    ratings: ratings.value,
  };
  return sources[type] || [];
};

const getFilterOptions = type => {
  if (type === 'ratings') {
    return ratings.value;
  }
  return buildFilterList(getFilterSource(type), type);
};

const filterListMenuItems = computed(() => {
  const filterTypes = [
    {
      id: '1',
      name: t('CSAT_REPORTS.FILTERS.AGENTS.LABEL'),
      type: 'agents',
    },
    {
      id: '2',
      name: t('CSAT_REPORTS.FILTERS.INBOXES.LABEL'),
      type: 'inboxes',
    },
    {
      id: '3',
      name: t('CSAT_REPORTS.FILTERS.RATINGS.LABEL'),
      type: 'ratings',
    },
  ];

  if (props.showTeamFilter) {
    filterTypes.splice(2, 0, {
      id: '4',
      name: t('CSAT_REPORTS.FILTERS.TEAMS.LABEL'),
      type: 'teams',
    });
  }

  const activeFilterKeys = Object.keys(appliedFilters.value).filter(
    key => appliedFilters.value[key]
  );
  const activeFilterTypes = activeFilterKeys.map(key =>
    getFilterType(key, 'keyToType')
  );

  return filterTypes
    .filter(({ type }) => !activeFilterTypes.includes(type))
    .map(({ id, name, type }) => ({
      id,
      name,
      type,
      options: getFilterOptions(type),
    }));
});

const activeFilters = computed(() => {
  const activeKeys = Object.keys(appliedFilters.value).filter(
    key => appliedFilters.value[key]
  );

  return activeKeys.map(key => {
    const filterType = getFilterType(key, 'keyToType');
    const items = getFilterSource(filterType);
    const item = getActiveFilter(items, filterType, appliedFilters.value[key]);
    const displayName =
      item?.name || item?.title || `ID: ${appliedFilters.value[key]}`;

    return {
      id: item?.id || appliedFilters.value[key],
      name: displayName,
      type: filterType,
      options: getFilterOptions(filterType),
    };
  });
});

const hasActiveFilters = computed(() =>
  Object.values(appliedFilters.value).some(value => value !== null)
);

const isAllFilterSelected = computed(() => !filterListMenuItems.value.length);

const updateURLParams = () => {
  const params = generateCompleteURLParams({
    from: from.value,
    to: to.value,
    range: selectedDateRange.value,
    filters: {
      agent_id: appliedFilters.value.user_ids,
      inbox_id: appliedFilters.value.inbox_id,
      team_id: appliedFilters.value.team_id,
      rating: appliedFilters.value.rating,
    },
  });
  router.replace({ query: params });
};

const emitChange = () => {
  updateURLParams();
  emit('filterChange', {
    from: from.value,
    to: to.value,
    selectedAgents: appliedFilters.value.user_ids
      ? [{ id: appliedFilters.value.user_ids }]
      : [],
    selectedInbox: appliedFilters.value.inbox_id
      ? { id: appliedFilters.value.inbox_id }
      : null,
    selectedTeam: appliedFilters.value.team_id
      ? { id: appliedFilters.value.team_id }
      : null,
    selectedRating: appliedFilters.value.rating
      ? { value: appliedFilters.value.rating }
      : null,
  });
};

const closeDropdown = () => {
  showDropdownMenu.value = false;
};

const closeActiveFilterDropdown = () => {
  activeFilterType.value = '';
  showSubDropdownMenu.value = false;
};

const resetDropdown = () => {
  closeDropdown();
  closeActiveFilterDropdown();
};

const addFilter = item => {
  const { type, id } = item;
  const filterKey = getFilterType(type, 'typeToKey');
  appliedFilters.value[filterKey] = id;
  emitChange();
  resetDropdown();
};

const removeFilter = type => {
  const filterKey = getFilterType(type, 'typeToKey');
  appliedFilters.value[filterKey] = null;
  emitChange();
};

const clearAllFilters = () => {
  appliedFilters.value = {
    user_ids: null,
    inbox_id: null,
    team_id: null,
    rating: null,
  };
  emitChange();
  resetDropdown();
};

const showDropdown = () => {
  showSubDropdownMenu.value = false;
  showDropdownMenu.value = !showDropdownMenu.value;
};

const openActiveFilterDropdown = filterType => {
  closeDropdown();
  activeFilterType.value = filterType;
  showSubDropdownMenu.value = !showSubDropdownMenu.value;
};

const onDateRangeChange = value => {
  const [startDate, endDate, rangeType] = value;
  customDateRange.value = [startDate, endDate];
  selectedDateRange.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  emitChange();
};

onMounted(() => {
  emitChange();
});
</script>

<template>
  <div class="flex flex-col flex-wrap w-full gap-3 md:flex-row">
    <WootDatePicker
      v-model:date-range="customDateRange"
      v-model:range-type="selectedDateRange"
      @date-range-changed="onDateRangeChange"
    />

    <div
      class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
    >
      <div v-if="hasActiveFilters" class="flex flex-wrap gap-2 md:flex-nowrap">
        <ActiveFilterChip
          v-for="filter in activeFilters"
          v-bind="filter"
          :key="filter.type"
          :placeholder="
            $t(
              `CSAT_REPORTS.FILTERS.INPUT_PLACEHOLDER.${filter.type.toUpperCase()}`
            )
          "
          :active-filter-type="activeFilterType"
          :show-menu="showSubDropdownMenu"
          enable-search
          @toggle-dropdown="openActiveFilterDropdown"
          @close-dropdown="closeActiveFilterDropdown"
          @add-filter="addFilter"
          @remove-filter="removeFilter"
        />
      </div>

      <div
        v-if="hasActiveFilters && !isAllFilterSelected"
        class="w-full h-px border md:w-px md:h-5 border-n-weak"
      />

      <div class="flex items-center gap-2">
        <AddFilterChip
          v-if="!isAllFilterSelected"
          placeholder-i18n-key="CSAT_REPORTS.FILTERS.INPUT_PLACEHOLDER"
          :name="$t('CSAT_REPORTS.FILTERS.ADD_FILTER')"
          :menu-option="filterListMenuItems"
          :show-menu="showDropdownMenu"
          :empty-state-message="$t('CSAT_REPORTS.FILTERS.NO_FILTER')"
          @toggle-dropdown="showDropdown"
          @close-dropdown="closeDropdown"
          @add-filter="addFilter"
        />

        <div v-if="hasActiveFilters" class="w-px h-5 border border-n-weak" />

        <FilterButton
          v-if="hasActiveFilters"
          :button-text="$t('CSAT_REPORTS.FILTERS.CLEAR_ALL')"
          @click="clearAllFilters"
        />
      </div>
    </div>
  </div>
</template>
