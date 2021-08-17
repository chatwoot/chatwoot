<template>
  <div class="contacts-page row">
    <div class="left-wrap" :class="wrapClas">
      <contacts-header
        :search-query="searchQuery"
        :on-search-submit="onSearchSubmit"
        this-selected-contact-id=""
        :on-input-search="onInputSearch"
        :on-toggle-create="onToggleCreate"
        :header-title="label"
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
    <contact-info-panel
      v-if="showContactViewPane"
      :contact="selectedContact"
      :on-close="closeContactInfoPanel"
    />
    <create-contact :show="showCreateModal" @cancel="onToggleCreate" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ContactsHeader from './Header';
import ContactsTable from './ContactsTable';
import ContactInfoPanel from './ContactInfoPanel';
import CreateContact from 'dashboard/routes/dashboard/conversation/contact/CreateContact';
import TableFooter from 'dashboard/components/widgets/TableFooter';

const DEFAULT_PAGE = 1;

export default {
  components: {
    ContactsHeader,
    ContactsTable,
    TableFooter,
    ContactInfoPanel,
    CreateContact,
  },
  props: {
    label: { type: String, default: '' },
  },
  data() {
    return {
      searchQuery: '',
      showCreateModal: false,
      selectedContactId: '',
      sortConfig: { name: 'asc' },
    };
  },
  computed: {
    ...mapGetters({
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
      meta: 'contacts/getMeta',
    }),
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
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
  },
  watch: {
    label() {
      this.fetchContacts(DEFAULT_PAGE);
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
      this.updatePageParam(page);
      const requestParams = {
        page,
        sortAttr: this.getSortAttribute(),
        label: this.label,
      };
      if (!this.searchQuery) {
        this.$store.dispatch('contacts/get', requestParams);
      } else {
        this.$store.dispatch('contacts/search', {
          search: this.searchQuery,
          ...requestParams,
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
      this.fetchContacts(page);
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
