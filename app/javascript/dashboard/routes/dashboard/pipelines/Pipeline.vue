<template>
  <div class="w-full flex flex-row">
    <div class="flex flex-col h-full" :class="wrapClass">
      <page-header
        :header-title="pageTitle"
        @on-filter-change="onFilterChange"
      />
      <board :selected-stage-type="selectedStageType" />
    </div>
  </div>
</template>

<script>
import PageHeader from './Header.vue';
import Board from './Board.vue';
import filterQueryGenerator from '../../../helper/filterQueryGenerator';
import { CONTACTS_EVENTS } from '../../../helper/AnalyticsHelper/events';

export default {
  components: {
    PageHeader,
    Board,
  },
  data() {
    return {
      selectedStageType: null,
      searchQuery: '',
      showCreateModal: false,
    };
  },
  computed: {
    pageTitle() {
      return this.$t('PIPELINE_PAGE.HEADER');
    },
    selectedContact() {
      if (this.selectedContactId) {
        const contact = this.records.find(
          item => this.selectedContactId === item.id
        );
        return contact;
      }
      return undefined;
    },
    showContactViewPane() {
      return false;
      // return this.selectedContactId !== '';
    },
    wrapClass() {
      return this.showContactViewPane ? 'w-[75%]' : 'w-full';
    },
  },
  mounted() {
    this.fetchContacts(this.pageParameter);
  },
  methods: {
    onFilterChange(selectedStageType) {
      this.selectedStageType = selectedStageType;
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
    fetchContacts(page) {
      if (this.isContactAndLabelDashboard) {
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
          label: this.label,
        };
        if (!value) {
          this.$store.dispatch('contacts/get', requestParams);
        } else {
          this.$store.dispatch('contacts/search', {
            search: encodeURIComponent(value),
            ...requestParams,
          });
        }
      }
    },

    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllContacts = !!this.searchQuery && newQuery === '';
      this.searchQuery = newQuery;
      if (refetchAllContacts) {
        this.fetchContacts();
      }
    },
    onSearchSubmit() {
      this.selectedContactId = '';
      if (this.searchQuery) {
        this.fetchContacts();
      }
    },
    openContactInfoPanel(contactId) {
      this.selectedContactId = contactId;
      this.showContactInfoPanelPane = true;
    },
    closeContactInfoPanel() {
      this.selectedContactId = '';
      this.showContactInfoPanelPane = false;
    },
    onToggleCreate() {
      this.showCreateModal = !this.showCreateModal;
    },
    onSortChange(params) {
      this.sortConfig = params;
      this.fetchContacts(this.meta.currentPage);

      const sortBy =
        Object.entries(params).find(pair => Boolean(pair[1])) || [];

      this.$track(CONTACTS_EVENTS.APPLY_SORT, {
        appliedOn: sortBy[0],
        order: sortBy[1],
      });
    },
    onApplyFilter(payload) {
      this.closeContactInfoPanel();
      this.segmentsQuery = filterQueryGenerator(payload);
      this.$store.dispatch('contacts/filter', {
        queryPayload: filterQueryGenerator(payload),
      });
      this.showFiltersModal = false;
    },
    clearFilters() {
      this.$store.dispatch('contacts/clearContactFilters');
      this.fetchContacts(this.pageParameter);
    },
  },
};
</script>
