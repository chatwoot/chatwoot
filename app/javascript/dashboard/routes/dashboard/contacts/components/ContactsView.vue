<template>
  <div class="contacts-page row">
    <div class="left-wrap" :class="wrapClas">
      <contacts-header
        :search-query="searchQuery"
        :segments-id="segmentsId"
        :on-search-submit="onSearchSubmit"
        this-selected-contact-id=""
        :on-input-search="onInputSearch"
        :on-toggle-create="onToggleCreate"
        :on-toggle-import="onToggleImport"
        :on-toggle-filter="onToggleFilters"
        :header-title="pageTitle"
        @on-toggle-save-filter="onToggleSaveFilters"
        @on-toggle-delete-filter="onToggleDeleteFilters"
      />
      <contacts-table
        :contacts="records"
        :show-search-empty-state="showEmptySearchResult"
        :is-loading="uiFlags.isFetching"
        :on-click-contact="openContactInfoPanel"
        :active-contact-id="selectedContactId"
        :sort-config="sortConfig"
        @on-sort-change="onSortChange"
      />
      <table-footer
        :on-page-change="onPageChange"
        :current-page="Number(meta.currentPage)"
        :total-count="meta.count"
      />
    </div>

    <add-custom-views
      v-if="showAddSegmentsModal"
      :custom-views-query="segmentsQuery"
      :filter-type="filterType"
      :open-last-saved-item="openSavedItemInSegment"
      @close="onCloseAddSegmentsModal"
    />
    <delete-custom-views
      v-if="showDeleteSegmentsModal"
      :show-delete-popup.sync="showDeleteSegmentsModal"
      :active-custom-view="activeSegment"
      :custom-views-id="segmentsId"
      :active-filter-type="filterType"
      :open-last-item-after-delete="openLastItemAfterDeleteInSegment"
      @close="onCloseDeleteSegmentsModal"
    />

    <contact-info-panel
      v-if="showContactViewPane"
      :contact="selectedContact"
      :on-close="closeContactInfoPanel"
    />
    <create-contact :show="showCreateModal" @cancel="onToggleCreate" />
    <woot-modal :show.sync="showImportModal" :on-close="onToggleImport">
      <import-contacts v-if="showImportModal" :on-close="onToggleImport" />
    </woot-modal>
    <woot-modal
      :show.sync="showFiltersModal"
      :on-close="onToggleFilters"
      size="medium"
    >
      <contacts-advanced-filters
        v-if="showFiltersModal"
        :on-close="onToggleFilters"
        :initial-filter-types="contactFilterItems"
        @applyFilter="onApplyFilter"
        @clearFilters="clearFilters"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ContactsHeader from './Header';
import ContactsTable from './ContactsTable';
import ContactInfoPanel from './ContactInfoPanel';
import CreateContact from 'dashboard/routes/dashboard/conversation/contact/CreateContact';
import TableFooter from 'dashboard/components/widgets/TableFooter';
import ImportContacts from './ImportContacts.vue';
import ContactsAdvancedFilters from './ContactsAdvancedFilters.vue';
import contactFilterItems from '../contactFilterItems';
import filterQueryGenerator from '../../../../helper/filterQueryGenerator';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews';

const DEFAULT_PAGE = 1;
const FILTER_TYPE_CONTACT = 1;

export default {
  components: {
    ContactsHeader,
    ContactsTable,
    TableFooter,
    ContactInfoPanel,
    CreateContact,
    ImportContacts,
    ContactsAdvancedFilters,
    AddCustomViews,
    DeleteCustomViews,
  },
  props: {
    label: { type: String, default: '' },
    segmentsId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {
      searchQuery: '',
      showCreateModal: false,
      showImportModal: false,
      selectedContactId: '',
      sortConfig: { name: 'asc' },
      showFiltersModal: false,
      contactFilterItems: contactFilterItems.map(filter => ({
        ...filter,
        attributeName: this.$t(
          `CONTACTS_FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
        ),
      })),
      segmentsQuery: {},
      filterType: FILTER_TYPE_CONTACT,
      showAddSegmentsModal: false,
      showDeleteSegmentsModal: false,
    };
  },
  computed: {
    ...mapGetters({
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
      meta: 'contacts/getMeta',
      segments: 'customViews/getCustomViews',
      getAppliedContactFilters: 'contacts/getAppliedContactFilters',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
    hasAppliedFilters() {
      return this.getAppliedContactFilters.length;
    },
    hasActiveSegments() {
      return this.activeSegment && this.segmentsId !== 0;
    },
    isContactAndLabelDashboard() {
      return (
        this.$route.name === 'contacts_dashboard' ||
        this.$route.name === 'contacts_labels_dashboard'
      );
    },
    pageTitle() {
      if (this.hasActiveSegments) {
        return this.activeSegment.name;
      }
      if (this.label) {
        return `#${this.label}`;
      }
      return this.$t('CONTACTS_PAGE.HEADER');
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
      return this.selectedContactId !== '';
    },
    wrapClas() {
      return this.showContactViewPane ? 'medium-9' : 'medium-12';
    },
    pageParameter() {
      const selectedPageNumber = Number(this.$route.query?.page);
      return !Number.isNaN(selectedPageNumber) &&
        selectedPageNumber >= DEFAULT_PAGE
        ? selectedPageNumber
        : DEFAULT_PAGE;
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
  },
  watch: {
    label() {
      this.fetchContacts(DEFAULT_PAGE);
      if (this.hasAppliedFilters) {
        this.clearFilters();
      }
    },
    activeSegment() {
      if (this.hasActiveSegments) {
        const payload = this.activeSegment.query;
        this.fetchSavedFilteredContact(payload, DEFAULT_PAGE);
      }
      if (this.hasAppliedFilters && this.$route.name === 'contacts_dashboard') {
        this.fetchFilteredContacts(DEFAULT_PAGE);
      } else {
        this.fetchContacts(DEFAULT_PAGE);
      }
    },
  },
  mounted() {
    this.fetchContacts(this.pageParameter);
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
        this.sortConfig = { name: 'asc' };
        sortAttr = 'name';
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
            search: value,
            ...requestParams,
          });
        }
      }
    },
    fetchSavedFilteredContact(payload, page) {
      if (this.hasActiveSegments) {
        this.updatePageParam(page);
        this.$store.dispatch('contacts/filter', {
          queryPayload: payload,
          page,
        });
      }
    },
    fetchFilteredContacts(page) {
      if (this.hasAppliedFilters) {
        const payload = this.segmentsQuery;
        this.updatePageParam(page);
        this.$store.dispatch('contacts/filter', {
          queryPayload: payload,
          page,
        });
      }
    },

    onInputSearch(event) {
      const newQuery = event.target.value;
      const refetchAllContacts = !!this.searchQuery && newQuery === '';
      this.searchQuery = newQuery;
      if (refetchAllContacts) {
        this.fetchContacts(DEFAULT_PAGE);
      }
    },
    onSearchSubmit() {
      this.selectedContactId = '';
      if (this.searchQuery) {
        this.fetchContacts(DEFAULT_PAGE);
      }
    },
    onPageChange(page) {
      this.selectedContactId = '';
      if (this.segmentsId !== 0) {
        const payload = this.activeSegment.query;
        this.fetchSavedFilteredContact(payload, page);
      }
      if (this.hasAppliedFilters) {
        this.fetchFilteredContacts(page);
      } else {
        this.fetchContacts(page);
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
    onToggleSaveFilters() {
      this.showAddSegmentsModal = true;
    },
    onCloseAddSegmentsModal() {
      this.showAddSegmentsModal = false;
    },
    onToggleDeleteFilters() {
      this.showDeleteSegmentsModal = true;
    },
    onCloseDeleteSegmentsModal() {
      this.showDeleteSegmentsModal = false;
    },
    onToggleImport() {
      this.showImportModal = !this.showImportModal;
    },
    onSortChange(params) {
      this.sortConfig = params;
      this.fetchContacts(this.meta.currentPage);
    },
    onToggleFilters() {
      this.showFiltersModal = !this.showFiltersModal;
    },
    onApplyFilter(payload) {
      this.closeContactInfoPanel();
      this.segmentsQuery = { payload };
      this.$store.dispatch('contacts/filter', {
        queryPayload: filterQueryGenerator(payload),
      });
      this.showFiltersModal = false;
    },
    clearFilters() {
      this.$store.dispatch('contacts/clearContactFilters');
      this.fetchContacts(this.pageParameter);
    },
    openSavedItemInSegment() {
      const lastItemInSegments = this.segments[this.segments.length - 1];
      const lastItemId = lastItemInSegments.id;
      this.$router.push({
        name: 'contacts_segments_dashboard',
        params: { id: lastItemId },
      });
    },
    openLastItemAfterDeleteInSegment() {
      if (this.segments.length > 0) {
        this.openSavedItemInSegment();
      } else {
        this.$router.push({ name: 'contacts_dashboard' });
        this.fetchContacts(DEFAULT_PAGE);
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.contacts-page {
  width: 100%;
}

.left-wrap {
  display: flex;
  flex-direction: column;
  height: 100%;
}
</style>
