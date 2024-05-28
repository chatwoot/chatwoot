<template>
  <div
    class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
  >
    <!-- Active filters section -->
    <div v-if="hasActiveFilters" class="flex flex-wrap gap-2 md:flex-nowrap">
      <active-filter-chip
        v-for="filter in activeFilters"
        v-bind="filter"
        :key="filter.type"
        :placeholder="
          $t(
            `SLA_REPORTS.DROPDOWN.INPUT_PLACEHOLDER.${filter.type.toUpperCase()}`
          )
        "
        :active-filter-type="activeFilterType"
        :show-menu="showSubDropdownMenu"
        enable-search
        @toggleDropdown="openActiveFilterDropdown"
        @closeDropdown="closeActiveFilterDropdown"
        @addFilter="addFilter"
        @removeFilter="removeFilter"
      />
    </div>
    <!-- Dividing line between Active filters and Add filter button -->
    <div
      v-if="hasActiveFilters && !isAllFilterSelected"
      class="w-full h-px border md:w-px md:h-5 border-slate-75 dark:border-slate-800"
    />
    <!-- Add filter and clear filter button -->
    <div class="flex items-center gap-2">
      <add-filter-chip
        v-if="!isAllFilterSelected"
        placeholder-i18n-key="SLA_REPORTS.DROPDOWN.INPUT_PLACEHOLDER"
        :name="$t('SLA_REPORTS.DROPDOWN.ADD_FIlTER')"
        :menu-option="filterListMenuItems"
        :show-menu="showDropdownMenu"
        :empty-state-message="$t('SLA_REPORTS.DROPDOWN.NO_FILTER')"
        @toggleDropdown="showDropdown"
        @closeDropdown="closeDropdown"
        @addFilter="addFilter"
      />

      <!-- Dividing line between Add filter and Clear all filter button -->
      <div
        v-if="hasActiveFilters"
        class="w-px h-5 border border-slate-75 dark:border-slate-800"
      />
      <!-- Clear all filter button -->
      <filter-button
        v-if="hasActiveFilters"
        :button-text="$t('SLA_REPORTS.DROPDOWN.CLEAR_ALL')"
        @click="clearAllFilters"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import {
  buildFilterList,
  getActiveFilter,
  getFilterType,
} from './helpers/SLAFilterHelpers';
import FilterButton from 'dashboard/components/ui/Dropdown/DropdownButton.vue';
import ActiveFilterChip from '../Filters/v3/ActiveFilterChip.vue';
import AddFilterChip from '../Filters/v3/AddFilterChip.vue';

export default {
  components: {
    FilterButton,
    ActiveFilterChip,
    AddFilterChip,
  },
  data() {
    return {
      showDropdownMenu: false,
      showSubDropdownMenu: false,
      activeFilterType: '',
      appliedFilters: {
        assigned_agent_id: null,
        inbox_id: null,
        team_id: null,
        sla_policy_id: null,
        label_list: null,
      },
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      inboxes: 'inboxes/getInboxes',
      teams: 'teams/getTeams',
      labels: 'labels/getLabels',
      sla: 'sla/getSLA',
    }),
    filterListMenuItems() {
      const filterTypes = [
        { id: '1', name: this.$t('SLA_REPORTS.DROPDOWN.SLA'), type: 'sla' },
        {
          id: '2',
          name: this.$t('SLA_REPORTS.DROPDOWN.INBOXES'),
          type: 'inboxes',
        },
        {
          id: '3',
          name: this.$t('SLA_REPORTS.DROPDOWN.AGENTS'),
          type: 'agents',
        },
        { id: '4', name: this.$t('SLA_REPORTS.DROPDOWN.TEAMS'), type: 'teams' },
        {
          id: '5',
          name: this.$t('SLA_REPORTS.DROPDOWN.LABELS'),
          type: 'labels',
        },
      ];
      // Filter out the active filters from the filter list
      // We only want to show the filters that are not already applied
      // In the add filter dropdown
      const activeFilters = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      const activeFilterTypes = activeFilters.map(key =>
        getFilterType(key, 'keyToType')
      );
      return filterTypes
        .filter(({ type }) => !activeFilterTypes.includes(type))
        .map(({ id, name, type }) => ({
          id,
          name,
          type,
          options: buildFilterList(this[type], type),
        }));
    },
    activeFilters() {
      // Get the active filters from the applied filters
      // and return the filter name, type and options
      const activeKey = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      return activeKey.map(key => {
        const filterType = getFilterType(key, 'keyToType');
        const item = getActiveFilter(
          this[filterType],
          filterType,
          this.appliedFilters[key]
        );
        return {
          id: item.id,
          name: filterType === 'labels' ? item.title : item.name,
          type: filterType,
          options: buildFilterList(this[filterType], filterType),
        };
      });
    },
    hasActiveFilters() {
      return Object.values(this.appliedFilters).some(value => value !== null);
    },
    isAllFilterSelected() {
      return !this.filterListMenuItems.length;
    },
  },
  methods: {
    addFilter(item) {
      const { type, id, name } = item;
      const filterKey = getFilterType(type, 'typeToKey');
      this.appliedFilters[filterKey] = type === 'labels' ? name : id;
      this.$emit('filter-change', this.appliedFilters);
      this.resetDropdown();
    },
    removeFilter(type) {
      const filterKey = getFilterType(type, 'typeToKey');
      this.appliedFilters[filterKey] = null;
      this.$emit('filter-change', this.appliedFilters);
    },
    clearAllFilters() {
      this.appliedFilters = {
        assigned_agent_id: null,
        inbox_id: null,
        team_id: null,
        sla_policy_id: null,
        label_list: null,
      };
      this.$emit('filter-change', this.appliedFilters);
      this.resetDropdown();
    },
    showDropdown() {
      this.showSubDropdownMenu = false;
      this.showDropdownMenu = !this.showDropdownMenu;
    },
    closeDropdown() {
      this.showDropdownMenu = false;
    },
    openActiveFilterDropdown(filterType) {
      this.closeDropdown();
      this.activeFilterType = filterType;
      this.showSubDropdownMenu = !this.showSubDropdownMenu;
    },
    closeActiveFilterDropdown() {
      this.activeFilterType = '';
      this.showSubDropdownMenu = false;
    },
    resetDropdown() {
      this.closeDropdown();
      this.closeActiveFilterDropdown();
    },
  },
};
</script>
