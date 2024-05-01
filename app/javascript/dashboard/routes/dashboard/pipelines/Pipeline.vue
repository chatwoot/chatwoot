<template>
  <div class="w-full flex flex-row">
    <div class="flex flex-col h-full" :class="wrapClass">
      <page-header
        :header-title="pageTitle"
        @on-filter-change="onFilterChange"
        @on-toggle-filter="onToggleFilters"
        @on-input-search="onInputSearch"
        @on-search-submit="onSearchSubmit"
      />
      <board
        :stages="stages"
        :contacts="records"
        :selected-contact-id="selectedContactId"
        @on-selected-contact="onSelectedContact"
        @add-contact-click="addContactClick"
      />
    </div>
    <contact-info-panel
      v-if="showContactViewPane"
      :contact="selectedContact"
      :on-close="closeContactInfoPanel"
    />
    <create-contact
      :contact="defaultContact"
      :show="showCreateModal"
      @cancel="onToggleCreate"
    />
    <woot-modal
      :show.sync="showFiltersModal"
      :on-close="closeAdvanceFiltersModal"
      size="medium"
    >
      <contacts-advanced-filters
        v-if="showFiltersModal"
        :on-close="closeAdvanceFiltersModal"
        :initial-filter-types="contactFilterItems"
        :initial-applied-filters="appliedFilter"
        @applyFilter="onApplyFilter"
        @clearFilters="clearFilters"
      />
    </woot-modal>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import PageHeader from './Header.vue';
import Board from './Board.vue';
import ContactInfoPanel from '../contacts/components/ContactInfoPanel.vue';
import boardsAPI from '../../../api/boards.js';
import CreateContact from '../conversation/contact/CreateContact.vue';
import filterQueryGenerator from '../../../helper/filterQueryGenerator';
import ContactsAdvancedFilters from '../contacts/components/ContactsAdvancedFilters.vue';
import contactFilterItems from '../contacts/contactFilterItems';

const DEFAULT_PAGE = 0;
const FILTER_TYPE_CONTACT = 1;

export default {
  components: {
    PageHeader,
    Board,
    ContactInfoPanel,
    CreateContact,
    ContactsAdvancedFilters,
    // eslint-disable-next-line vue/no-unused-components
    contactFilterItems,
  },
  data() {
    return {
      stages: [],
      contacts: [],
      selectedStageType: null,
      selectedContactId: '',
      defaultContact: null,
      searchQuery: '',
      showCreateModal: false,
      showFiltersModal: false,
      appliedFilter: [],
      contactFilterItems: contactFilterItems.map(filter => ({
        ...filter,
        attributeName: this.$t(
          `CONTACTS_FILTER.ATTRIBUTES.${filter.attributeI18nKey}`
        ),
      })),
      filterType: FILTER_TYPE_CONTACT,
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
    selectedContact() {
      if (this.selectedContactId) {
        const contact = this.records.find(
          item => this.selectedContactId === item.id
        );
        return contact;
      }
      return undefined;
    },
    hasAppliedFilters() {
      return this.getAppliedContactFilters.length;
    },
    pageTitle() {
      return this.$t('PIPELINE_PAGE.HEADER');
    },
    showContactViewPane() {
      return this.selectedContactId !== '';
    },
    wrapClass() {
      return this.showContactViewPane ? 'w-[75%]' : 'w-full';
    },
  },
  methods: {
    onSelectedContact(contactId) {
      this.selectedContactId = contactId;
    },
    onToggleFilters() {
      this.showFiltersModal = true;
    },
    closeAdvanceFiltersModal() {
      this.showFiltersModal = false;
      this.appliedFilter = [];
    },
    onFilterChange(selectedStageType) {
      this.selectedContactId = '';
      this.selectedStageType = selectedStageType.value;
      const stageType = this.selectedStageType;
      boardsAPI.get().then(response => {
        const stagesByType = response.data.filter(
          item =>
            stageType === 'both' ||
            item.stage_type === 'both' ||
            item.stage_type === stageType
        );
        this.stages = stagesByType;
        this.fetchContacts();
      });
    },
    fetchContacts() {
      let value = '';
      if (this.searchQuery.charAt(0) === '+') {
        value = this.searchQuery.substring(1);
      } else {
        value = this.searchQuery;
      }
      const requestParams = {
        page: DEFAULT_PAGE,
        stageType: this.selectedStageType,
      };
      if (!value) {
        this.$store.dispatch('contacts/get', requestParams);
      } else {
        this.$store.dispatch('contacts/search', {
          search: encodeURIComponent(value),
          ...requestParams,
        });
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
    addContactClick(stageId) {
      this.defaultContact = { stage_id: stageId };
      this.onToggleCreate();
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
