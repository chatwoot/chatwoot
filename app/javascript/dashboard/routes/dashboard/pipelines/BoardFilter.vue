<template>
  <div
    class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
  >
    <!-- Active filters section -->
    <div v-if="hasActiveFilters" class="flex flex-wrap gap-2 md:flex-nowrap">
      <active-filter-chip
        v-for="filter in activeFilters"
        v-bind="filter"
        :key="filter.key"
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
        placeholder-i18n-key="PIPELINE_PAGE.FILTER.INPUT_PLACEHOLDER"
        :name="$t('PIPELINE_PAGE.FILTER.ADD_FIlTER')"
        :menu-option="filterListMenuItems"
        :show-menu="showDropdownMenu"
        :empty-state-message="$t('PIPELINE_PAGE.FILTER.NO_FILTER')"
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
        :button-text="$t('PIPELINE_PAGE.FILTER.CLEAR_ALL')"
        @click="clearAllFilters"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import FilterButton from '../settings/reports/components/Filters/v3/FilterButton.vue';
import ActiveFilterChip from '../settings/reports/components/Filters/v3/ActiveFilterChip.vue';
import AddFilterChip from '../settings/reports/components/Filters/v3/AddFilterChip.vue';

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
        agent_id: null,
        product_id: null,
        team_id: null,
        label_id: null,
      },
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      products: 'products/getProducts',
      teams: 'teams/getTeams',
      labels: 'labels/getLabels',
    }),
    filterAttributes() {
      const filters = [
        {
          id: 1,
          key: 'agent_id',
          name: this.$t('PIPELINE_PAGE.FILTER.AGENTS'),
          type: 'agents',
        },
        {
          id: 2,
          key: 'product_id',
          name: this.$t('PIPELINE_PAGE.FILTER.PRODUCTS'),
          type: 'products',
        },
        {
          id: 3,
          key: 'team_id',
          name: this.$t('PIPELINE_PAGE.FILTER.TEAMS'),
          type: 'teams',
        },
        {
          id: 4,
          key: 'label_id',
          name: this.$t('PIPELINE_PAGE.FILTER.LABELS'),
          type: 'labels',
        },
      ];
      return filters.map(item => {
        return {
          ...item,
          options: this[item.type].map(option => {
            return {
              id: option.id,
              name: option.name || option.title,
              key: item.key,
            };
          }),
        };
      });
    },
    customFilters() {
      const allCustomAttributes =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );
      return allCustomAttributes
        .filter(attr => attr.attribute_display_type === 'list')
        .map((attr, i) => ({
          id: i + 5,
          key: attr.attribute_key,
          name: attr.attribute_display_name,
          type: attr.attribute_key,
          options: attr.attribute_values.map(item => {
            return {
              id: item,
              name: item,
              key: attr.attribute_key,
            };
          }),
        }));
    },
    filterListMenuItems() {
      const filterTypes = [...this.filterAttributes, ...this.customFilters];

      const activeFilters = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      return filterTypes
        .filter(({ key }) => !activeFilters.includes(key))
        .map(({ id, key, name, type, options }) => ({
          id,
          key,
          name,
          type,
          options,
        }));
    },
    activeFilters() {
      return this.updateActiveFilters();
    },
    hasActiveFilters() {
      return Object.values(this.appliedFilters).some(value => value !== null);
    },
    isAllFilterSelected() {
      return !this.filterListMenuItems.length;
    },
  },
  watch: {
    appliedFilters: {
      immediate: true,
      handler() {
        this.updateActiveFilters();
      },
    },
  },
  mounted() {
    this.$store.dispatch('products/get');
    this.$store.dispatch('agents/get');
  },
  methods: {
    updateActiveFilters() {
      const filterTypes = [...this.filterAttributes, ...this.customFilters];

      const activeFilters = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      return filterTypes
        .filter(({ key }) => activeFilters.includes(key))
        .map(({ id, key, type, options }) => ({
          id,
          key,
          name: options.find(item => item.id === this.appliedFilters[key]).name,
          type,
          options,
        }));
    },
    addFilter(item) {
      const { key, id } = item;
      this.appliedFilters[key] = id;
      this.$emit('filter-change', this.appliedFilters);
      this.resetDropdown();
    },
    removeFilter(key) {
      this.appliedFilters[key] = null;
      this.$emit('filter-change', this.appliedFilters);
    },
    clearAllFilters() {
      this.appliedFilters = {
        agent_id: null,
        product_id: null,
        team_id: null,
        label_id: null,
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
