<template>
  <div class="flex flex-row w-full">
    <div class="flex flex-col h-full" :class="wrapClass">
      <integrations-view-header
        :header-title="$t('ORDERS_PAGE.HEADER')"
        :segments-id="segmentsId"
        @on-input-search="onInputSearch"
        @on-search-submit="onSearchSubmit"
        @on-toggle-update="onToggleUpdate"
        @on-toggle-filter="onToggleFilters"
        @on-toggle-edit-filter="onToggleFilters"
        @on-toggle-delete-filter="onToggleDeleteFilters"
        @on-toggle-save-filter="onToggleSaveFilters"
      />
      <integrations-table
        :orders="records"
        :show-search-empty-state="false"
        :is-loading="uiFlags.isFetching"
        :on-click-order="openOrderInfoPanel"
        :active-order-id="null"
      />
      <table-footer
        class="border-t border-slate-75 dark:border-slate-700/50"
        :current-page="Number(meta.currentPage)"
        :total-count="meta.count"
        :page-size="15"
        @page-change="onPageChange"
      />
    </div>

    <integrations-info-panel
      v-if="showOrderViewPane"
      :order="selectedOrder"
      :on-close="closeOrderInfoPanel"
    />

    <woot-modal
      :show.sync="showFiltersModal"
      :on-close="closeAdvanceFiltersModal"
      size="medium"
    >
      <orders-advanced-filters
        v-if="showFiltersModal"
        :on-close="closeAdvanceFiltersModal"
        :initial-filter-types="orderFilterItems"
        :initial-applied-filters="appliedFilter"
        :active-segment-name="activeSegmentName"
        :is-segments-view="hasActiveSegments"
        @applyFilter="onApplyFilter"
        @updateSegment="onUpdateSegment"
        @clearFilters="clearFilters"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import integrationsTable from './integrationsTable.vue';
import integrationsInfoPanel from './integrationsInfoPanel.vue';
import IntegrationsViewHeader from './Header.vue';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import orderFilterItems from '../orderFilterItems';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import ordersAdvancedFilters from './ordersAdvancedFilters.vue';
import filterQueryGenerator from '../../../../helper/filterQueryGenerator';

const DEFAULT_PAGE = 1;
const FILTER_TYPE_ORDER = 1;

export default {
  components: {
    integrationsTable,
    integrationsInfoPanel,
    IntegrationsViewHeader,
    ordersAdvancedFilters,
    TableFooter,
  },

  props: {
    segmentsId: {
      type: [String, Number],
      default: 0,
    },
  },

  data() {
    return {
      searchQuery: '',
      sortConfig: { last_activity_at: 'desc' },
      selectedOrdertId: '',
      orderFilterItems: orderFilterItems.map(filter => ({
        ...filter,
        attributeName: this.$t(
          `ORDERS_FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
        ),
      })),
      showFiltersModal: false,
      appliedFilter: [],
      segmentsQuery: {},
    };
  },

  computed: {
    ...mapGetters({
      records: 'integrationsView/getIntegrationsView',
      uiFlags: 'integrationsView/getUIFlags',
      meta: 'integrationsView/getMeta',
      // segments: 'customViews/getCustomViews',
      getAppliedOrdersFilters: 'integrationsView/getAppliedOrdersFilters',
    }),

    showOrderViewPane() {
      return this.selectedOrdertId !== '';
    },

    pageParameter() {
      const selectedPageNumber = Number(this.$route.query?.page);
      return !Number.isNaN(selectedPageNumber) &&
        selectedPageNumber >= DEFAULT_PAGE
        ? selectedPageNumber
        : DEFAULT_PAGE;
    },

    hasAppliedFilters() {
      return this.getAppliedOrdersFilters.length;
    },

    selectedOrder() {
      if (this.selectedOrdertId) {
        const order = this.records.find(
          item => this.selectedOrdertId === item.id
        );
        return order;
      }
      return undefined;
    },

    wrapClass() {
      return this.showOrderViewPane ? 'w-[75%]' : 'w-full';
    },
    activeSegment() {
      if (this.segmentsId) {
        const [firstValue] = this.segments.filter(
          view => view.id === Number(this.segmentsId)
        );

        return firstValue;
      }
      return undefined;
    },
    activeSegmentName() {
      return this.activeSegment?.name;
    },

    hasActiveSegments() {
      return this.activeSegment && this.segmentsId !== 0;
    },
  },

  mounted() {
    this.fetchOrders(this.pageParameter);
  },

  methods: {
    updatePageParam(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
    },
    getSortAttribute() {
      let sortAttr = Object.keys(this.sortConfig).reduce((acc, sortKey) => {
        const sortOrder = this.sortConfig[sortKey];
        if (sortOrder) {
          const sortOrderSign = sortOrder === 'asc' ? '' : '-';
          return `${sortOrderSign}${sortKey}`;
        }
        return acc;
      }, '');
      if (!sortAttr) {
        this.sortConfig = { last_activity_at: 'desc' };
        sortAttr = '-last_activity_at';
      }
      return sortAttr;
    },

    fetchOrders(page) {
      this.updatePageParam(page);
      let value = '';
      if (this.searchQuery.charAt(0) === '+') {
        value = this.searchQuery.substring(1);
      } else {
        value = this.searchQuery;
      }
      const requestParams = {
        page,
        sortAttr: this.getSortAttribute(),
      };
      if (!value) {
        this.$store.dispatch('integrationsView/get', requestParams);
      } else {
        this.$store.dispatch('integrationsView/search', {
          search: encodeURIComponent(value),
          ...requestParams,
        });
      }
    },
    fetchSavedFilteredOrders(payload, page) {
      if (this.hasActiveSegments) {
        this.updatePageParam(page);
        this.$store.dispatch('integrationsView/filter', {
          queryPayload: payload,
          page,
        });
      }
    },

    fetchFilteredOrders(page) {
      if (this.hasAppliedFilters) {
        const payload = this.segmentsQuery;
        this.updatePageParam(page);
        this.$store.dispatch('integrationsView/filter', {
          queryPayload: payload,
          page,
        });
      }
    },

    closeAdvanceFiltersModal() {
      this.showFiltersModal = false;
      this.appliedFilter = [];
    },

    openOrderInfoPanel(orderId) {
      this.selectedOrdertId = orderId;
    },

    closeOrderInfoPanel() {
      this.selectedOrdertId = '';
    },

    async onToggleUpdate() {
      const updateOders = await this.$store.dispatch('integrationsView/update');
      updateOders.then(() => this.$store.dispatch('integrationsView/get'));
    },

    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllOrders = !!this.searchQuery && newQuery === '';
      this.searchQuery = newQuery;
      if (refetchAllOrders) {
        this.fetchOrders(DEFAULT_PAGE);
      }
    },
    onSearchSubmit() {
      this.selectedOrderId = '';
      if (this.searchQuery) {
        this.fetchOrders(DEFAULT_PAGE);
      }
    },

    onToggleFilters() {
      if (this.hasActiveSegments) {
        this.initializeSegmentToFilterModal(this.activeSegment);
      }
      this.showFiltersModal = true;
    },
    onToggleDeleteFilters() {
      this.showDeleteSegmentsModal = true;
    },
    onToggleSaveFilters() {
      this.showAddSegmentsModal = true;
    },

    setParamsForEditSegmentModal() {
      // Here we are setting the params for edit segment modal to show the existing values.

      // For custom attributes we get only attribute key.
      // So we are mapping it to find the input type of the attribute to show in the edit segment modal.
      const params = {
        countries: countries,
        filterTypes: contactFilterItems,
        allCustomAttributes:
          this.$store.getters['attributes/getAttributesByModel'](
            'contact_attribute'
          ),
      };
      return params;
    },

    initializeSegmentToFilterModal(activeSegment) {
      // Here we are setting the params for edit segment modal.
      //  To show the existing values. when we click on edit segment button.

      // Here we get the query from the active segment.
      // And we are mapping the query to the actual values.
      // To show in the edit segment modal by the help of generateValuesForEditCustomViews helper.
      const query = activeSegment?.query?.payload;
      if (!Array.isArray(query)) return;

      this.appliedFilter.push(
        ...query.map(filter => ({
          attribute_key: filter.attribute_key,
          attribute_model: filter.attribute_model,
          filter_operator: filter.filter_operator,
          values: Array.isArray(filter.values)
            ? generateValuesForEditCustomViews(
                filter,
                this.setParamsForEditSegmentModal()
              )
            : [],
          query_operator: filter.query_operator,
          custom_attribute_type: filter.custom_attribute_type,
        }))
      );
    },
    onApplyFilter(payload) {
      this.closeOrderInfoPanel();
      this.segmentsQuery = filterQueryGenerator(payload);
      this.$store.dispatch('integrationsView/filter', {
        queryPayload: filterQueryGenerator(payload),
      });
      this.showFiltersModal = false;
    },

    onUpdateSegment(payload, segmentName) {
      const payloadData = {
        ...this.activeSegment,
        name: segmentName,
        query: filterQueryGenerator(payload),
      };
      this.$store.dispatch('customViews/update', payloadData);
      this.closeAdvanceFiltersModal();
    },

    clearFilters() {
      this.$store.dispatch('integrationsView/clearOrdersFilters');
      this.fetchOrders(this.pageParameter);
    },

    onPageChange(page) {
      this.selectedOrdertId = '';
      if (this.segmentsId !== 0) {
        const payload = this.activeSegment.query;
        this.fetchSavedFilteredOrders(payload, page);
      }
      if (this.hasAppliedFilters) {
        this.fetchFilteredOrders(page);
      } else {
        this.fetchOrders(page);
      }
    },
  },
};
</script>
