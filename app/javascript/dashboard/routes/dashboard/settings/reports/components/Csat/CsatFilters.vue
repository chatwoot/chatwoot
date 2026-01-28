<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import {
  buildFilterList,
  buildRatingsList,
  getFilterType,
} from './CsatFilterHelpers';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import AddFilterChip from '../Filters/v3/AddFilterChip.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';

const props = defineProps({
  showTeamFilter: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['filterChange']);

const { t } = useI18n();
const store = useStore();

const showDropdownMenu = ref(false);
const customDateRange = ref([new Date(), new Date()]);
const appliedFilters = ref({
  user_ids: [],
  inbox_id: [],
  team_id: [],
  rating: null,
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

  const options = buildFilterList(getFilterSource(type), type);
  const filterKey = getFilterType(type, 'typeToKey');
  const selectedIds = appliedFilters.value[filterKey] || [];

  if (Array.isArray(selectedIds) && selectedIds.length > 0) {
    return options.filter(option => !selectedIds.includes(option.id));
  }

  return options;
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

  return filterTypes.map(({ id, name, type }) => ({
    id,
    name,
    type,
    options: getFilterOptions(type),
  }));
});

const selectedItemsChips = computed(() => {
  const chips = [];

  if (appliedFilters.value.user_ids?.length > 0) {
    appliedFilters.value.user_ids.forEach(userId => {
      const agent = agents.value.find(a => a.id === userId);
      if (agent) {
        chips.push({
          id: userId,
          name: agent.name,
          type: 'agents',
          filterKey: 'user_ids',
        });
      }
    });
  }

  if (appliedFilters.value.inbox_id?.length > 0) {
    appliedFilters.value.inbox_id.forEach(inboxId => {
      const inbox = inboxes.value.find(i => i.id === inboxId);
      if (inbox) {
        chips.push({
          id: inboxId,
          name: inbox.name,
          type: 'inboxes',
          filterKey: 'inbox_id',
        });
      }
    });
  }

  if (appliedFilters.value.team_id?.length > 0) {
    appliedFilters.value.team_id.forEach(teamId => {
      const team = teams.value.find(item => item.id === teamId);
      if (team) {
        chips.push({
          id: teamId,
          name: team.name,
          type: 'teams',
          filterKey: 'team_id',
        });
      }
    });
  }

  if (appliedFilters.value.rating !== null) {
    const rating = ratings.value.find(
      r => r.id === appliedFilters.value.rating
    );
    if (rating) {
      chips.push({
        id: appliedFilters.value.rating,
        name: rating.name,
        type: 'ratings',
        filterKey: 'rating',
      });
    }
  }

  return chips;
});

const hasActiveFilters = computed(() =>
  Object.values(appliedFilters.value).some(value =>
    Array.isArray(value) ? value.length > 0 : value !== null
  )
);

const emitChange = () => {
  emit('filterChange', {
    from: from.value,
    to: to.value,
    selectedAgents: appliedFilters.value.user_ids.map(id => ({ id })),
    selectedInbox: appliedFilters.value.inbox_id.map(id => ({ id })),
    selectedTeam: appliedFilters.value.team_id.map(id => ({ id })),
    selectedRating: appliedFilters.value.rating
      ? { value: appliedFilters.value.rating }
      : null,
  });
};

const closeDropdown = () => {
  showDropdownMenu.value = false;
};

const addFilter = item => {
  const { type, id } = item;
  const filterKey = getFilterType(type, 'typeToKey');

  if (type === 'ratings') {
    appliedFilters.value[filterKey] = id;
    emitChange();
    closeDropdown();
  } else {
    if (!appliedFilters.value[filterKey]) {
      appliedFilters.value[filterKey] = [];
    }

    if (!appliedFilters.value[filterKey].includes(id)) {
      appliedFilters.value[filterKey].push(id);
      emitChange();
    }
  }
};

const removeItem = (filterKey, itemId) => {
  if (filterKey === 'rating') {
    appliedFilters.value[filterKey] = null;
  } else {
    const index = appliedFilters.value[filterKey].indexOf(itemId);
    if (index !== -1) {
      appliedFilters.value[filterKey].splice(index, 1);
    }
  }

  emitChange();
};

const clearAllFilters = () => {
  appliedFilters.value = {
    user_ids: [],
    inbox_id: [],
    team_id: [],
    rating: null,
  };
  emitChange();
  closeDropdown();
};

const showDropdown = () => {
  showDropdownMenu.value = !showDropdownMenu.value;
};

const onDateRangeChange = value => {
  customDateRange.value = value;
  emitChange();
};

onMounted(() => {
  emitChange();
});
</script>

<template>
  <div class="flex flex-col flex-wrap w-full gap-3 md:flex-row">
    <WootDatePicker @date-range-changed="onDateRangeChange" />

    <div
      class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
    >
      <div v-if="hasActiveFilters" class="flex flex-wrap gap-2">
        <button
          v-for="chip in selectedItemsChips"
          :key="`${chip.filterKey}-${chip.id}`"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-full bg-n-25 dark:bg-n-700 text-n-900 dark:text-n-25 hover:bg-n-50 dark:hover:bg-n-600 transition-colors"
          @click="removeItem(chip.filterKey, chip.id)"
        >
          <span>{{ chip.name }}</span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-4 h-4"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
              clip-rule="evenodd"
            />
          </svg>
        </button>
      </div>

      <div
        v-if="hasActiveFilters"
        class="w-full h-px border md:w-px md:h-5 border-n-weak"
      />

      <div class="flex items-center gap-2">
        <AddFilterChip
          placeholder-i18n-key="CSAT_REPORTS.FILTERS.INPUT_PLACEHOLDER"
          :name="$t('CSAT_REPORTS.FILTERS.ADD_FILTER')"
          :menu-option="filterListMenuItems"
          :show-menu="showDropdownMenu"
          :empty-state-message="$t('CSAT_REPORTS.FILTERS.NO_FILTER')"
          enable-search
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
