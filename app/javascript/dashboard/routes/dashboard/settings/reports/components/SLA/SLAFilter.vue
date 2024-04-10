<template>
  <div
    class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
  >
    <!-- Active filters section -->
    <div v-if="hasActiveFilters" class="flex flex-wrap gap-2 md:flex-nowrap">
      <filter-button
        v-for="filter in activeFilters"
        :key="filter.type"
        :button-text="filter.name"
        class="bg-slate-50 dark:bg-slate-800 hover:bg-slate-75 dark:hover:bg-slate-800"
        @click="openActiveFilterDropdown(filter.type)"
      >
        <template #rightIcon>
          <fluent-icon
            icon="chevron-down"
            size="18"
            class="flex-shrink-0 text-slate-900 dark:text-slate-50"
          />
        </template>
        <template
          v-if="showSubDropdownMenu && activeFilterType === filter.type"
          #dropdown
        >
          <filter-list-dropdown
            v-if="filter.options"
            v-on-clickaway="closeActiveFilterDropdown"
            :list-items="filter.options"
            :active-filter-id="filter.id"
            :button-text="$t('SLA_REPORTS.DROPDOWN.CLEAR_FILTER')"
            :empty-list-message="$t('SLA_REPORTS.DROPDOWN.EMPTY_LIST')"
            :input-placeholder="
              $t(
                `SLA_REPORTS.DROPDOWN.INPUT_PLACEHOLDER.${filter.type.toUpperCase()}`
              )
            "
            enable-search
            class="flex flex-col w-[240px] overflow-y-auto left-0 md:left-auto md:right-0 top-10"
            @click="addFilter"
            @removeFilter="removeFilter(filter.type)"
          />
        </template>
      </filter-button>
    </div>
    <!-- Dividing line between Active filters and Add filter button -->
    <div
      v-if="hasActiveFilters"
      class="w-full h-px border md:w-px md:h-5 border-slate-75 dark:border-slate-800"
    />
    <!-- Add filter and clear filter button -->
    <div class="flex items-center gap-2">
      <filter-button
        :button-text="$t('SLA_REPORTS.DROPDOWN.ADD_FIlTER')"
        @click="showDropdown"
      >
        <template #leftIcon>
          <fluent-icon
            icon="filter"
            size="18"
            class="flex-shrink-0 text-slate-900 dark:text-slate-50"
          />
        </template>
        <!-- Dropdown with search and sub-dropdown -->
        <template v-if="showDropdownMenu" #dropdown>
          <filter-list-dropdown
            v-on-clickaway="closeDropdown"
            class="left-0 md:right-0 top-10"
          >
            <template #listItem>
              <filter-dropdown-empty-state
                v-if="!filterListMenuItems.length"
                :message="$t('SLA_REPORTS.DROPDOWN.NO_FILTER')"
              />
              <filter-list-item-button
                v-for="item in filterListMenuItems"
                :key="item.id"
                :button-text="item.name"
                @mouseenter="showSubMenu(item.id)"
                @mouseleave="hideSubMenu"
                @focus="showSubMenu(item.id)"
              >
                <!-- Submenu with search and clear button  -->
                <template v-if="item.options && isHovered(item.id)" #dropdown>
                  <filter-list-dropdown
                    :list-items="item.options"
                    :empty-list-message="$t('SLA_REPORTS.DROPDOWN.EMPTY_LIST')"
                    :input-placeholder="
                      $t(
                        `SLA_REPORTS.DROPDOWN.INPUT_PLACEHOLDER.${item.type.toUpperCase()}`
                      )
                    "
                    enable-search
                    class="flex flex-col w-[216px] overflow-y-auto top-0 left-36"
                    @click="addFilter"
                  />
                </template>
              </filter-list-item-button>
            </template>
          </filter-list-dropdown>
        </template>
      </filter-button>
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
import { mixin as clickaway } from 'vue-clickaway';
import FilterButton from '../Filters/v3/FilterButton.vue';
import FilterListDropdown from '../Filters/v3/FilterListDropdown.vue';
import FilterListItemButton from '../Filters/v3/FilterListItemButton.vue';
import FilterDropdownEmptyState from '../Filters/v3/FilterDropdownEmptyState.vue';

export default {
  components: {
    FilterButton,
    FilterListDropdown,
    FilterListItemButton,
    FilterDropdownEmptyState,
  },
  mixins: [clickaway],
  data() {
    return {
      showDropdownMenu: false,
      showSubDropdownMenu: false,
      activeFilterType: '',
      hoveredItemId: null,
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
        this.getFilterType(key, 'keyToType')
      );
      return filterTypes
        .filter(({ type }) => !activeFilterTypes.includes(type))
        .map(({ id, name, type }) => ({
          id,
          name,
          type,
          options: this.buildFilterList(this[type], type),
        }));
    },
    activeFilters() {
      // Get the active filters from the applied filters
      // and return the filter name, type and options
      const activeKey = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      return activeKey.map(key => {
        const filterType = this.getFilterType(key, 'keyToType');
        const item = this.getActiveFilterName(filterType, key);
        return {
          id: item.id,
          name: filterType === 'labels' ? item.title : item.name,
          type: filterType,
          options: this.buildFilterList(this[filterType], filterType),
        };
      });
    },
    hasActiveFilters() {
      return this.activeFilters.length > 0;
    },
  },
  methods: {
    addFilter(item) {
      const { type, id, name } = item;
      const filterKey = this.getFilterType(type, 'typeToKey');
      this.appliedFilters[filterKey] = type === 'labels' ? name : id;
      this.$emit('filter-change', this.appliedFilters);
      this.resetDropdown();
    },
    removeFilter(type) {
      const filterKey = this.getFilterType(type, 'typeToKey');
      this.appliedFilters[filterKey] = null;
      this.$emit('filter-change', this.appliedFilters);
    },
    buildFilterList(items, type) {
      // Build the filter list for the dropdown
      return items.map(item => ({
        id: item.id,
        name: type === 'labels' ? item.title : item.name,
        type,
      }));
    },
    getActiveFilterName(type, key) {
      return this[type].find(filterItem =>
        type === 'labels'
          ? filterItem.title === this.appliedFilters[key]
          : filterItem.id.toString() === this.appliedFilters[key].toString()
      );
    },
    getFilterType(input, direction) {
      // Method is used to map the filter key to the filter type
      const filterMap = {
        keyToType: {
          assigned_agent_id: 'agents',
          inbox_id: 'inboxes',
          team_id: 'teams',
          sla_policy_id: 'sla',
          label_list: 'labels',
        },
        typeToKey: {
          agents: 'assigned_agent_id',
          inboxes: 'inbox_id',
          teams: 'team_id',
          sla: 'sla_policy_id',
          labels: 'label_list',
        },
      };
      return filterMap[direction][input];
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
      this.hoveredItemId = null;
    },
    showSubMenu(itemId) {
      this.hoveredItemId = itemId;
    },
    hideSubMenu() {
      this.hoveredItemId = null;
    },
    isHovered(itemId) {
      return this.hoveredItemId?.toString() === itemId.toString();
    },
  },
};
</script>
