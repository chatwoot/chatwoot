<template>
  <div
    class="flex flex-col flex-wrap items-start gap-2 md:items-center md:flex-nowrap md:flex-row"
  >
    <!-- Active filters section -->
    <div v-if="hasActiveFilters" class="flex flex-wrap gap-2 md:flex-nowrap">
      <active-filter-chip
        v-for="filter in activeFilters"
        v-bind="filter"
        :id="appliedFilters[filter.key]"
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
  props: {
    appliedFiltersProp: {
      type: Object,
      default: () => {},
    },
    segmentsQuery: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      showDropdownMenu: false,
      showSubDropdownMenu: false,
      activeFilterType: '',
      appliedFilters: {},
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      teams: 'teams/getTeams',
      labels: 'labels/getLabels',
    }),
    products() {
      return this.hasActiveFilters && !this.hasProductFilterOnly
        ? this.$store.getters['contacts/getAvailableProducts']
        : this.$store.getters['products/getProducts'];
    },
    conversation_plans() {
      return [
        {
          id: 'today',
          name: this.$t('PIPELINE_PAGE.CONVERSATION_PLANS_FILTER_TYPE.TODAY'),
        },
        {
          id: 'this_week',
          name: this.$t(
            'PIPELINE_PAGE.CONVERSATION_PLANS_FILTER_TYPE.THIS_WEEK'
          ),
        },
        {
          id: 'unresolved',
          name: this.$t(
            'PIPELINE_PAGE.CONVERSATION_PLANS_FILTER_TYPE.UNRESOLVED'
          ),
        },
        {
          id: 'all',
          name: this.$t('PIPELINE_PAGE.CONVERSATION_PLANS_FILTER_TYPE.ALL'),
        },
      ];
    },
    customViews() {
      const customViews =
        this.$store.getters['customViews/getCustomViewsByFilterType'](
          'contact'
        );

      if (
        !this.appliedFilters.custom_view ||
        this.appliedFilters.custom_view === 'new'
      ) {
        customViews.push({
          id: 'new',
          name: `+++ ${this.$t('PIPELINE_PAGE.FILTER_CONTACTS')} +++`,
        });
      }

      return customViews;
    },
    filterAttributes() {
      const filters = [
        {
          id: 0,
          key: 'conversation_plan',
          name: this.$t('PIPELINE_PAGE.FILTER.CONVERSATION_PLANS'),
          type: 'conversation_plans',
        },
        {
          id: 1,
          key: 'assignee_id',
          name: this.$t('PIPELINE_PAGE.FILTER.AGENTS'),
          type: 'agents',
        },
        {
          id: 2,
          key: 'team_id',
          name: this.$t('PIPELINE_PAGE.FILTER.TEAMS'),
          type: 'teams',
        },
        {
          id: 3,
          key: 'product_id',
          name: this.$t('PIPELINE_PAGE.FILTER.PRODUCTS'),
          type: 'products',
        },
        {
          id: 4,
          key: 'label',
          name: this.$t('PIPELINE_PAGE.FILTER.LABELS'),
          type: 'labels',
        },
      ];
      return filters.map(item => {
        return {
          ...item,
          options: this[item.type].map(option => {
            return {
              id: item.key === 'label' ? option.title : option.id,
              name: this.getOptionName(option, item.key),
              key: item.key,
            };
          }),
        };
      });
    },
    customFilters() {
      const contactCustomAttributes =
        this.$store.getters['attributes/getAttributesByModel'](
          'contact_attribute'
        );
      const productCustomAttributes =
        this.$store.getters['attributes/getAttributesByModel'](
          'product_attribute'
        );

      const allCustomAttributes = [
        ...contactCustomAttributes,
        ...productCustomAttributes.map(i => ({
          attribute_key: `product_custom_attr.${i.attribute_key}`,
          attribute_display_name: i.attribute_display_name,
          attribute_values: i.attribute_values,
          attribute_display_type: i.attribute_display_type,
        })),
      ];

      const formattedAttributes = allCustomAttributes
        .filter(attr => attr.attribute_display_type === 'list')
        .map((attr, i) => ({
          id: i + this.filterAttributes.length,
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

      return [
        ...formattedAttributes,
        {
          id: this.filterAttributes.length + formattedAttributes.length,
          key: 'custom_view',
          name: this.$t('PIPELINE_PAGE.FILTER.CUSTOM_VIEWS'),
          type: 'customViews',
          options: this.customViews.map(option => {
            return {
              id: option.id,
              name: option.name,
              key: 'custom_view',
            };
          }),
        },
      ];
    },
    filterListMenuItems() {
      const filterTypes = [...this.filterAttributes, ...this.customFilters];

      const activeFilters = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      if (
        activeFilters.includes('custom_view') ||
        activeFilters.includes('label')
      ) {
        return [];
      }
      return filterTypes
        .filter(({ key }) => !activeFilters.includes(key))
        .map(({ id, key, name, options }) => ({
          id,
          key,
          name,
          type: key,
          options,
        }));
    },
    activeFilters() {
      const filterTypes = [...this.filterAttributes, ...this.customFilters];

      const activeFilters = Object.keys(this.appliedFilters).filter(
        key => this.appliedFilters[key]
      );
      return filterTypes
        .filter(({ key }) => activeFilters.includes(key))
        .map(({ id, key, options }) => ({
          id,
          key,
          name: options.find(item => item.id === this.appliedFilters[key])
            ?.name,
          type: key,
          options,
        }));
    },
    hasActiveFilters() {
      return Object.values(this.appliedFilters).some(value => value !== null);
    },
    hasProductFilter() {
      return Object.keys(this.appliedFilters).some(key => key === 'product_id');
    },
    hasProductFilterOnly() {
      return (
        this.hasProductFilter && Object.keys(this.appliedFilters).length === 1
      );
    },
    isAllFilterSelected() {
      return !this.filterListMenuItems.length;
    },
  },
  watch: {
    appliedFiltersProp() {
      this.appliedFilters = this.appliedFiltersProp;
    },
    segmentsQuery() {
      if (this.hasActiveFilters && !this.hasProductFilter) {
        this.$store.dispatch('contacts/availableProducts', this.segmentsQuery);
      }
    },
  },
  mounted() {
    this.$store.dispatch('products/get', { page: 0 });
    this.$store.dispatch('agents/get');
  },
  methods: {
    getOptionName(option, key) {
      switch (key) {
        case 'label':
          return option.description || option.title;
        case 'product_id':
          return (
            (option.short_name ? option.short_name + ' - ' : '') + option.name
          );
        default:
          return option.name;
      }
    },
    addFilter(item) {
      const { key, id } = item;
      if (key === 'custom_view' || key === 'label') {
        this.appliedFilters = {};
      }
      const newFilters = { ...this.appliedFilters, [key]: id };
      this.appliedFilters = newFilters;
      this.$emit('filter-change', this.appliedFilters);
      this.resetDropdown();
    },
    removeFilter(key) {
      this.appliedFilters[key] = null;
      this.$emit('filter-change', this.appliedFilters);
    },
    clearAllFilters() {
      this.appliedFilters = {};
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
