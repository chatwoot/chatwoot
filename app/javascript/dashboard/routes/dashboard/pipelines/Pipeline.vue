<template>
  <div class="w-full flex flex-row">
    <div class="flex flex-col h-full" :class="wrapClass">
      <page-header
        :search-query="searchQuery"
        :header-title="pageTitle"
        :stage-type-value="stageTypeValue"
        :assignee-type-value="assigneeTypeValue"
        :display-options="displayOptions"
        :custom-views="customViews"
        :custom-view-value="customViewValue"
        @on-assignee-type-change="onAssigneeTypeChange"
        @on-filter-change="onFilterChange"
        @on-toggle-filter="onToggleFilters"
        @on-input-search="onInputSearch"
        @on-search-submit="onSearchSubmit"
        @on-toggle-save-filter="onToggleSaveFilters"
        @on-toggle-delete-filter="onToggleDeleteFilters"
        @on-toggle-edit-filter="onToggleFilters"
        @display-option-changed="onDisplayOptionChanged"
        @on-custom-view-change="onCustomViewChange"
        @on-quick-filters-change="onQuickFiltersChange"
      />
      <board
        :stages="stages"
        :contacts="records"
        :selected-contact-id="selectedContactId"
        :display-options="displayOptions"
        @on-selected-contact="onSelectedContact"
        @add-contact-click="addContactClick"
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
        :active-segment-name="activeSegmentName"
        :account-scoped="activeAccountScope"
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
import { frontendURL } from '../../../helper/URLHelper';

import PageHeader from './Header.vue';
import Board from './Board.vue';
import ContactInfoPanel from '../contacts/components/ContactInfoPanel.vue';
import CreateContact from '../conversation/contact/CreateContact.vue';
import filterQueryGenerator from '../../../helper/filterQueryGenerator';
import ContactsAdvancedFilters from '../contacts/components/ContactsAdvancedFilters.vue';
import contactFilterItems from '../contacts/contactFilterItems';
import AddCustomViews from 'dashboard/routes/dashboard/customviews/AddCustomViews.vue';
import DeleteCustomViews from 'dashboard/routes/dashboard/customviews/DeleteCustomViews.vue';
import { generateValuesForEditCustomViews } from 'dashboard/helper/customViewsHelper';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import adminMixin from 'dashboard/mixins/isAdmin';

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
    AddCustomViews,
    DeleteCustomViews,
  },
  mixins: [adminMixin, uiSettingsMixin],
  props: {
    segmentsId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {
      contacts: [],
      stageTypeValue: 'both',
      assigneeTypeValue: null,
      customViewValue: null,
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
      segmentsQuery: {},
      filterType: FILTER_TYPE_CONTACT,
      showAddSegmentsModal: false,
      showDeleteSegmentsModal: false,
      displayOptions: {
        lastStageChangedAt: false,
        assignee: false,
        lastActivityAt: true,
        lastNote: true,
        currentAction: true,
      },
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      records: 'contacts/getContacts',
      uiFlags: 'contacts/getUIFlags',
      segments: 'customViews/getCustomViews',
      getAppliedContactFilters: 'contacts/getAppliedContactFilters',
    }),
    customViews() {
      return this.$store.getters['customViews/getCustomViewsByFilterType'](
        'contact'
      );
    },
    stages() {
      return this.$store.getters['stages/getStagesByType'](
        this.stageTypeValue,
        false
      );
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
    hasActiveSegments() {
      return this.activeSegment && this.segmentsId !== 0;
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
    activeAccountScope() {
      return this.activeSegment?.account_scoped;
    },
  },
  watch: {
    activeSegment() {
      this.fetchContacts();
    },
    customViewValue() {
      if (this.customViewValue) {
        const route = frontendURL(
          `accounts/${this.accountId}/pipelines/custom_view/${this.customViewValue}`
        );
        this.$router.push(route);
      } else {
        this.$router.push({ name: 'pipelines_dashboard' });
      }
    },
  },
  mounted() {
    this.$store.dispatch('stages/get');
    this.$store.dispatch('contacts/clearContactFilters');

    this.$store.dispatch('customViews/get', 'contact').then(() => {
      this.loadUISettings();
    });
  },
  methods: {
    loadUISettings() {
      const { pipeline_view } = this.uiSettings;
      if (pipeline_view) {
        this.assigneeTypeValue = pipeline_view.assignee_type;
        this.stageTypeValue = pipeline_view.stage_type;
        this.customViewValue = pipeline_view.custom_view;
        this.displayOptions = pipeline_view.display_options;
      } else {
        if (!this.isAdmin) this.assigneeTypeValue = 'me';
        if (this.customViews.length > 0)
          this.customViewValue = this.customViews[0].id;
      }

      if (!this.customViewValue) {
        this.fetchContacts();
      }
    },
    onDisplayOptionChanged(option) {
      this.displayOptions[option.key] = !option.selected;
    },
    onCustomViewChange(selectedView) {
      this.customViewValue = selectedView?.id;
    },
    setParamsForEditSegmentModal() {
      // Here we are setting the params for edit segment modal to show the existing values.

      // For custom attributes we get only attribute key.
      // So we are mapping it to find the input type of the attribute to show in the edit segment modal.
      const params = {
        stages: this.stages,
        agents: this.agents,
        teams: this.teams,
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
    onSelectedContact(contactId) {
      this.selectedContactId = contactId;
    },
    onToggleFilters() {
      if (this.hasActiveSegments) {
        this.initializeSegmentToFilterModal(this.activeSegment);
      }
      this.showFiltersModal = true;
    },
    closeAdvanceFiltersModal() {
      this.showFiltersModal = false;
      this.appliedFilter = [];
    },
    onFilterChange(selectedStageType) {
      this.selectedContactId = '';
      this.stageTypeValue = selectedStageType.value;
      this.fetchContacts();
    },
    onAssigneeTypeChange(selectedAssigneeType) {
      this.selectedContactId = '';
      this.assigneeTypeValue = selectedAssigneeType?.id;
      this.fetchContacts();
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
        stageType: this.stageTypeValue,
        assigneeType: this.assigneeTypeValue,
      };
      if (value) {
        this.$store.dispatch('contacts/search', {
          search: encodeURIComponent(value),
          ...requestParams,
        });
      } else if (this.hasActiveSegments) {
        this.$store.dispatch('contacts/filter', {
          ...requestParams,
          queryPayload: this.activeSegment.query,
        });
      } else if (this.hasAppliedFilters) {
        this.$store.dispatch('contacts/filter', {
          ...requestParams,
          queryPayload: this.segmentsQuery,
        });
      } else this.$store.dispatch('contacts/get', requestParams);
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
    onQuickFiltersChange(quickFilters) {
      const filters = Object.keys(quickFilters).filter(
        key => quickFilters[key]
      );
      if (filters.length === 0) {
        this.fetchContacts();
        return;
      }
      const payload = filters.map(key => {
        return {
          attribute_key: key,
          filter_operator: 'equal_to',
          values: { id: quickFilters[key] },
          query_operator: 'and',
          attribute_model: 'standard',
        };
      });

      this.$store.dispatch('contacts/filter', {
        page: DEFAULT_PAGE,
        stageType: this.stageTypeValue,
        queryPayload: filterQueryGenerator(payload),
      });
    },
    onApplyFilter(payload) {
      this.closeContactInfoPanel();
      this.segmentsQuery = filterQueryGenerator(payload);
      this.$store.dispatch('contacts/filter', {
        page: DEFAULT_PAGE,
        stageType: this.stageTypeValue,
        queryPayload: filterQueryGenerator(payload),
      });
      this.showFiltersModal = false;
    },
    onUpdateSegment(payload, segmentName, accountScoped) {
      const payloadData = {
        ...this.activeSegment,
        name: segmentName,
        account_scoped: accountScoped,
        query: filterQueryGenerator(payload),
      };
      this.$store.dispatch('customViews/update', payloadData);
      this.closeAdvanceFiltersModal();
    },
    clearFilters() {
      this.$store.dispatch('contacts/clearContactFilters');
      this.fetchContacts();
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
    openSavedItemInSegment() {
      const lastItemInSegments = this.segments[this.segments.length - 1];
      const lastItemId = lastItemInSegments.id;
      this.$router.push({
        name: 'pipelines_segments_dashboard',
        params: { id: lastItemId },
      });
    },
    openLastItemAfterDeleteInSegment() {
      if (this.segments.length > 0) {
        this.openSavedItemInSegment();
      } else {
        this.$router.push({ name: 'pipelines_dashboard' });
        this.fetchContacts(DEFAULT_PAGE);
      }
    },
  },
};
</script>
