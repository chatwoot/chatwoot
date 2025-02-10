<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import ContactsAPI from 'dashboard/api/contacts';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'ContactSelector',
  components: {
    Spinner,
  },
  props: {
    contacts: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    hasMore: {
      type: Boolean,
      default: false,
    },
  },
  emits: [
    'contactsSelected',
    'loadMore',
    'selectAllContacts',
    'filterContacts',
  ],
  data() {
    return {
      searchQuery: '',
      localSelectedContacts: [],
      observer: null,
      isSelectingAll: false,
      showFiltersModal: false,
      currentPage: 1,
      totalPages: 1,
      contactList: [],
      allFilteredContacts: [],
      isLoadingContacts: false,
      isFetchingAllPages: false,
      sortAttribute: 'name',
      appliedFilters: [
        {
          attribute_key: 'name',
          filter_operator: 'equal_to',
          values: '',
          query_operator: 'and',
        },
      ],
      filterTypes: [
        {
          attributeKey: 'name',
          attributeI18nKey: 'NAME',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
        {
          attributeKey: 'phone_number',
          attributeI18nKey: 'PHONE',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
        {
          attributeKey: 'email',
          attributeI18nKey: 'EMAIL',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
        {
          attributeKey: 'company',
          attributeI18nKey: 'COMPANY',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
        {
          attributeKey: 'city',
          attributeI18nKey: 'CITY',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
        {
          attributeKey: 'country_code',
          attributeI18nKey: 'COUNTRY',
          inputType: 'text',
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            // { value: 'not_equal_to', label: 'Does not equal' },
            // { value: 'contains', label: 'Contains' },
            // { value: 'does_not_contain', label: 'Does not contain' },
          ],
        },
      ],
      selectAllVisible: false, // Add this new data property
      selectVisibleCheckboxStyle: {
        marginLeft: '0px',
      },
    };
  },
  computed: {
    ...mapGetters({
      customAttributes: 'attributes/getAttributesByModel',
    }),
    mergedFilterTypes() {
      const standardTypes = this.filterTypes;
      const customTypes = this.customAttributes('contact_attribute').map(
        attr => ({
          attributeKey: attr.attribute_key,
          attributeI18nKey: attr.attribute_display_name,
          inputType: attr.attribute_display_type,
          filterOperators: [
            { value: 'equal_to', label: 'Equals' },
            { value: 'not_equal_to', label: 'Does not equal' },
            { value: 'contains', label: 'Contains' },
            { value: 'does_not_contain', label: 'Does not contain' },
          ],
          attributeModel: 'contact_attribute',
        })
      );
      return [...standardTypes, ...customTypes];
    },
    filteredContacts() {
      // Use contactList instead of contacts for filtering
      const contactsToFilter =
        this.contactList.length > 0 ? this.contactList : this.contacts;

      if (!this.searchQuery) return contactsToFilter;

      return contactsToFilter.filter(contact => {
        const searchLower = this.searchQuery.toLowerCase();
        return (
          (contact.name && contact.name.toLowerCase().includes(searchLower)) ||
          (contact.phone_number &&
            contact.phone_number.includes(this.searchQuery)) ||
          (contact.email && contact.email.toLowerCase().includes(searchLower))
        );
      });
    },
    hasAppliedFilters() {
      return this.appliedFilters.some(
        filter => filter.values && filter.values.trim() !== ''
      );
    },
  },
  watch: {
    contacts() {
      this.$nextTick(() => {
        if (this.$refs.loadingTrigger && this.observer) {
          this.observer.observe(this.$refs.loadingTrigger);
        }
      });
    },
    // Add this new watcher
    selectAllVisible(newValue) {
      if (newValue) {
        // Select all visible contacts
        this.filteredContacts.forEach(contact => {
          if (!this.isSelected(contact)) {
            this.localSelectedContacts.push(contact);
          }
        });
      } else {
        // Deselect all visible contacts
        this.localSelectedContacts = this.localSelectedContacts.filter(
          selectedContact =>
            !this.filteredContacts.some(
              contact => contact.id === selectedContact.id
            )
        );
      }
      this.$emit('contactsSelected', this.localSelectedContacts);
    },

    // Add this watcher to reset selectAllVisible when contacts change
    'filteredContacts.length'() {
      this.selectAllVisible = false;
    },
    filteredContacts: {
      handler() {
        this.updateSelectVisiblePosition();
      },
      immediate: true,
    },
  },
  mounted() {
    this.setupInfiniteScroll();
    this.updateSelectVisiblePosition();
    window.addEventListener('resize', this.updateSelectVisiblePosition);
  },
  beforeUnmount() {
    if (this.observer) {
      this.observer.disconnect();
    }
    window.removeEventListener('resize', this.updateSelectVisiblePosition);
  },
  methods: {
    async selectAll() {
      if (this.isFetchingAllPages) return;
      this.isSelectingAll = true;
      const hasActiveFilters = this.appliedFilters.some(
        filter => filter.values.trim() !== ''
      );

      try {
        // Clear previous selection
        this.localSelectedContacts = [];

        // If we have filtered contacts, use those instead of all contacts
        if (hasActiveFilters) {
          // Use the filtered contacts list
          this.localSelectedContacts = [...this.allFilteredContacts];
          await this.$emit('selectAllContacts', true, this.allFilteredContacts);
        } else {
          // Use the regular contacts list
          this.localSelectedContacts = [...this.contacts];
          await this.$emit('selectAllContacts', false, []);
        }

        this.$emit('contactsSelected', this.localSelectedContacts);
      } finally {
        this.isSelectingAll = false;
      }
    },

    handleContactsResponse(data, isFiltered = false) {
      const { payload = [], meta = {} } = data;
      const filteredContacts = payload.filter(contact => contact.phone_number);

      if (isFiltered) {
        this.contactList =
          this.currentPage === 1
            ? filteredContacts
            : [...this.contactList, ...filteredContacts];

        // Update allFilteredContacts only on first page for filtered results
        if (this.currentPage === 1) {
          this.allFilteredContacts = filteredContacts;
        } else {
          this.allFilteredContacts = [...this.allFilteredContacts];
        }
      } else {
        this.contactList =
          this.currentPage === 1
            ? filteredContacts
            : [...this.contactList, ...filteredContacts];
      }

      this.$emit('filterContacts', this.contactList);

      // Calculate total pages
      const totalpages = Math.ceil(meta.count / 30);
      this.totalPages = Math.min(totalpages, 33);

      this.$nextTick(() => {
        this.resetObserver();
      });
    },

    setupInfiniteScroll() {
      const options = {
        root: this.$refs.contactsList,
        rootMargin: '0px',
        threshold: 0.5,
      };

      this.observer = new IntersectionObserver(async ([entry]) => {
        if (entry.isIntersecting && !this.isLoading) {
          const hasActiveFilters = this.appliedFilters.some(
            filter => filter.values.trim() !== ''
          );

          if (hasActiveFilters) {
            // Use internal pagination state for filtered results
            if (this.currentPage < this.totalPages) {
              await this.loadMoreFilteredContacts();
            }
          } else {
            // Use parent's hasMore prop for non-filtered results
            if (this.hasMore) {
              this.$emit('loadMore');
            }
          }
        }
      }, options);

      this.$nextTick(() => {
        if (this.$refs.loadingTrigger) {
          this.observer.observe(this.$refs.loadingTrigger);
        }
      });
    },

    toggleContact(contact) {
      const index = this.localSelectedContacts.findIndex(
        c => c.id === contact.id
      );
      if (index === -1) {
        this.localSelectedContacts.push(contact);
      } else {
        this.localSelectedContacts.splice(index, 1);
      }
      this.$emit('contactsSelected', this.localSelectedContacts);
    },

    isSelected(contact) {
      return (this.localSelectedContacts || []).some(c => c.id === contact.id);
    },

    clearSelection() {
      this.localSelectedContacts = [];
      this.$emit('contactsSelected', this.localSelectedContacts);
    },

    toggleFiltersModal() {
      this.showFiltersModal = !this.showFiltersModal;
    },

    appendNewFilter() {
      this.appliedFilters.push({
        attribute_key: 'name',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
      });
    },

    removeFilter(index) {
      if (this.appliedFilters.length > 1) {
        this.appliedFilters.splice(index, 1);
      }
    },

    async submitFilters() {
      try {
        this.contactList = [];
        this.currentPage = 1;
        this.allFilteredContacts = []; // Reset filtered contacts

        const formattedFilters = this.appliedFilters
          .filter(filter => filter.values.trim() !== '')
          .map((filter, index, filteredArray) => ({
            attribute_key: filter.attribute_key,
            attribute_model: filter.attributeModel || 'standard',
            custom_attribute_type: '',
            filter_operator: filter.filter_operator,
            ...(filteredArray.length > 1 && index < filteredArray.length - 1
              ? { query_operator: filter.query_operator }
              : {}),
            values: [filter.values.trim()],
          }));

        if (formattedFilters.length === 0) {
          await this.fetchContacts(1);
          this.showFiltersModal = false;
          return;
        }

        this.isLoadingContacts = true;
        this.isFetchingAllPages = true;
        const queryPayload = { payload: formattedFilters };

        const { data } = await ContactsAPI.filter(1, 'name', queryPayload);
        this.handleContactsResponse(data, true);
        this.showFiltersModal = false;

        const { payload = [], meta = {} } = data;

        const validContacts = payload.filter(contact => contact.phone_number);
        this.allFilteredContacts = [...validContacts];

        // Fetch remaining pages
        const totalpages = Math.ceil(meta.count / 30);
        this.totalPages = totalpages;
        for (let page = 2; page <= totalpages; page++) {
          const response = await ContactsAPI.filter(page, 'name', queryPayload);
          if (response.data && response.data.payload) {
            const validPageContacts = response.data.payload.filter(
              contact => contact.phone_number
            );
            this.allFilteredContacts = [
              ...this.allFilteredContacts,
              ...validPageContacts,
            ];
          }
        }
        // Reset the observer after filtering
        this.$nextTick(() => {
          this.resetObserver();
        });
      } catch (error) {
        useAlert(this.$t('CAMPAIGN.CONTACT_SELECTOR.FILTER_ERROR'));
      } finally {
        this.isFetchingAllPages = false;
        this.isLoadingContacts = false;
      }
    },
    resetObserver() {
      if (this.observer) {
        this.observer.disconnect();
      }
      this.setupInfiniteScroll();
    },

    async loadMoreContacts() {
      if (this.currentPage < this.totalPages && !this.isLoadingContacts) {
        // Check if we have active filters
        const hasActiveFilters = this.appliedFilters.some(
          filter => filter.values.trim() !== ''
        );

        if (hasActiveFilters) {
          await this.loadMoreFilteredContacts();
        } else {
          this.currentPage += 1;
          await this.fetchContacts(this.currentPage);
        }
      }
    },

    async loadMoreFilteredContacts() {
      if (this.currentPage < this.totalPages && !this.isLoadingContacts) {
        try {
          this.isLoadingContacts = true;
          this.currentPage += 1;

          const formattedFilters = this.appliedFilters
            .filter(filter => filter.values.trim() !== '')
            .map((filter, index, filteredArray) => ({
              attribute_key: filter.attribute_key,
              attribute_model: 'standard',
              custom_attribute_type: '',
              filter_operator: filter.filter_operator,
              ...(filteredArray.length > 1 && index < filteredArray.length - 1
                ? { query_operator: filter.query_operator }
                : {}),
              values: [filter.values.trim()],
            }));

          const queryPayload = {
            payload: formattedFilters,
          };

          const { data } = await ContactsAPI.filter(
            this.currentPage,
            'name',
            queryPayload
          );

          this.handleContactsResponse(data, true);
        } catch (error) {
          useAlert(this.$t('CAMPAIGN.CONTACT_SELECTOR.FILTER_ERROR'));
          // Reset the page on error
          this.currentPage -= 1;
        } finally {
          this.isLoadingContacts = false;
        }
      }
    },

    async fetchContacts(page = 1) {
      try {
        this.isLoadingContacts = true;
        const { data } = await ContactsAPI.get(page, this.sortAttribute);
        this.handleContactsResponse(data, false);
      } catch (error) {
        useAlert(this.$t('CAMPAIGN.ADD.API.CONTACTS_ERROR'));
      } finally {
        this.isLoadingContacts = false;
      }
    },

    async clearFilters() {
      try {
        // Reset filters
        this.appliedFilters = [
          {
            attribute_key: 'name',
            filter_operator: 'equal_to',
            values: '',
            query_operator: 'and',
          },
        ];

        // Reset all contact-related data
        this.contactList = [];
        this.allFilteredContacts = [];
        this.currentPage = 1;
        this.totalPages = 1;

        // Fetch original contacts
        // await this.fetchContacts(1);

        // Emit filters cleared event
        this.$emit('filtersCleared');

        // Reset observer to handle infinite scroll
        this.resetObserver();

        // Close the modal
        this.showFiltersModal = false;
      } catch (error) {
        useAlert(this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE'));
      }
    },

    updateSelectedContacts(contactIds) {
      const currentSelectedIds = new Set(
        this.localSelectedContacts.map(c => c.id)
      );

      contactIds.forEach(id => {
        if (!currentSelectedIds.has(id)) {
          const contact = this.contacts.find(c => c.id === id);
          if (contact) {
            this.localSelectedContacts.push(contact);
          } else {
            this.localSelectedContacts.push({ id: id });
          }
        }
      });

      this.$emit('contactsSelected', this.localSelectedContacts);
    },

    getFilterOperators(attributeKey) {
      const filterType = this.mergedFilterTypes.find(
        type => type.attributeKey === attributeKey
      );
      return filterType ? filterType.filterOperators : [];
    },
    updateSelectVisiblePosition() {
      this.$nextTick(() => {
        const contactCheckbox = document.querySelector(
          '.contact-item input[type="checkbox"]'
        );
        if (contactCheckbox) {
          const checkboxRect = contactCheckbox.getBoundingClientRect();
          const containerRect = this.$el.getBoundingClientRect();
          const marginLeft = `${
            checkboxRect.left - containerRect.left - 430
          }px`; // 16px for padding
          this.selectVisibleCheckboxStyle = {
            marginLeft,
          };
        }
      });
    },
  },
};
</script>

<template>
  <div class="contact-selector">
    <div class="search-header">
      <div class="search-controls">
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('CAMPAIGN.CONTACT_SELECTOR.SEARCH_PLACEHOLDER')"
          class="search-input"
        />
        <div class="filter-button-container">
          <div
            v-if="hasAppliedFilters"
            class="absolute w-2 h-2 rounded-full top-1 right-1"
            :style="{ backgroundColor: '#369eff' }"
          />
          <woot-button
            v-tooltip.top-end="$t('CAMPAIGN.CONTACT_SELECTOR.FILTER')"
            icon="filter"
            size="medium"
            color-scheme="secondary"
            class="[&>span]:hidden xs:[&>span]:block"
            class-name="filter-button"
            @click="toggleFiltersModal"
          >
          </woot-button>
        </div>
      </div>
      <div class="selection-wrapper">
        <div class="selection-controls">
          <button @click="selectAll" :disabled="isFetchingAllPages">
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.SELECT_ALL') }}
          </button>
          <button @click="clearSelection">
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.CLEAR') }}
          </button>
        </div>
        <div
          class="select-visible-checkbox"
          :style="selectVisibleCheckboxStyle"
        >
          <input
            type="checkbox"
            :checked="selectAllVisible"
            @change="selectAllVisible = !selectAllVisible"
          />
        </div>
      </div>
    </div>

    <div v-if="isFetchingAllPages" class="loading-state">
      <Spinner />
      <span>{{ $t('CAMPAIGN.CONTACT_SELECTOR.LOADING_ALL_CONTACTS') }}</span>
    </div>

    <div v-else ref="contactsList" class="contacts-list">
      <div
        v-for="contact in filteredContacts"
        :key="contact.id"
        class="contact-item"
        :class="{ selected: isSelected(contact) }"
        @click="toggleContact(contact)"
      >
        <div class="contact-info">
          <span class="contact-name">{{ contact.name }}</span>
          <span class="contact-phone">{{ contact.phone_number }}</span>
          <span v-if="contact.email" class="contact-email">{{
            contact.email
          }}</span>
        </div>
        <input
          type="checkbox"
          :checked="isSelected(contact)"
          @click.stop="toggleContact(contact)"
        />
      </div>

      <div
        v-if="hasMore"
        ref="loadingTrigger"
        class="loading-trigger"
        :class="{ 'is-loading': isLoading }"
      >
        <span v-if="isLoading">{{
          $t('CAMPAIGN.CONTACT_SELECTOR.LOADING')
        }}</span>
      </div>
    </div>

    <div class="selection-summary">
      {{
        $t('CAMPAIGN.CONTACT_SELECTOR.SELECTED_CONTACTS', {
          count: localSelectedContacts.length,
        })
      }}
    </div>

    <!-- Filters Modal -->
    <woot-modal
      :show.sync="showFiltersModal"
      :on-close="toggleFiltersModal"
      size="medium"
    >
      <div class="filters-modal">
        <div class="filters-header">
          <h3>{{ $t('CAMPAIGN.CONTACT_SELECTOR.FILTER_TITLE') }}</h3>
          <p class="filters-subtitle">
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.FILTER_SUBTITLE') }}
          </p>
        </div>

        <div class="filters-content">
          <div
            v-for="(filter, index) in appliedFilters"
            :key="index"
            class="filter-row"
          >
            <select v-model="filter.attribute_key" class="filter-attribute">
              <option
                v-for="type in mergedFilterTypes"
                :key="type.attributeKey"
                :value="type.attributeKey"
              >
                {{ type.attributeKey }}
              </option>
            </select>

            <select v-model="filter.filter_operator" class="filter-operator">
              <option
                v-for="operator in getFilterOperators(filter.attribute_key)"
                :key="operator.value"
                :value="operator.value"
              >
                {{ operator.label }}
              </option>
            </select>

            <input
              v-model="filter.values"
              type="text"
              class="filter-value"
              :placeholder="
                $t('CAMPAIGN.CONTACT_SELECTOR.FILTER_VALUE_PLACEHOLDER')
              "
            />
            <woot-button
              v-if="appliedFilters.length > 1"
              icon="delete"
              size="medium"
              color-scheme="alert"
              class="remove-filter"
              @click="removeFilter(index)"
            />
          </div>
          <woot-button
            icon="add-circle"
            size="large"
            color-scheme="success"
            @click="appendNewFilter"
          >
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.ADD_FILTER') }}
          </woot-button>
        </div>

        <div class="filters-footer">
          <woot-button
            size="large"
            color-scheme="secondary"
            @click="clearFilters"
          >
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.CLEAR') }}
          </woot-button>
          <woot-button
            size="large"
            color-scheme="primary"
            @click="submitFilters"
          >
            {{ $t('CAMPAIGN.CONTACT_SELECTOR.APPLY') }}
          </woot-button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>

<style lang="scss" scoped>
.loading-state {
  @apply flex flex-col items-center justify-center p-8 text-slate-500 dark:text-slate-400;
  min-height: 200px;

  .spinner {
    @apply mb-4;
  }
}
.contact-selector {
  @apply flex flex-col h-full;

  .search-header {
    @apply flex items-center justify-between p-4 border-b 
           bg-white dark:bg-slate-800 
           border-slate-200 dark:border-slate-700;

    .search-controls {
      @apply flex items-center gap-2;

      .search-input {
        @apply w-64 px-3 py-2 border rounded
               bg-white dark:bg-slate-700 
               border-slate-300 dark:border-slate-600
               text-slate-900 dark:text-white
               placeholder-slate-500 dark:placeholder-slate-400;
        &:focus {
          @apply outline-none ring-2 ring-black-500;
        }
      }

      .filter-button-container {
        position: relative;
        display: inline-block;
        bottom: 7px;

        .filter-button {
          @apply relative bottom-4;
        }
      }
    }

    .selection-wrapper {
      @apply flex flex-col;

      .selection-controls {
        @apply flex flex-row gap-2;

        button {
          @apply px-3 py-1 text-sm border rounded
                 bg-white dark:bg-slate-700
                 border-slate-300 dark:border-slate-600
                 text-slate-700 dark:text-white
                 hover:bg-slate-50 hover:dark:bg-slate-600;
        }
      }

      .select-visible-checkbox {
        @apply flex items-center mt-4 text-sm text-slate-700 dark:text-white;

        input[type='checkbox'] {
          @apply w-4 h-4 cursor-pointer accent-black-600;
        }
      }
    }
  }

  .contacts-list {
    @apply flex-1 overflow-y-auto bg-white dark:bg-slate-900;
    max-height: 400px;

    .contact-item {
      @apply flex items-center justify-between p-3 cursor-pointer
             border-b border-slate-100 dark:border-slate-700
             hover:bg-slate-50 dark:hover:bg-slate-800;

      &.selected {
        @apply bg-black-50 dark:bg-black-900/30;
      }

      .contact-info {
        @apply flex flex-col;

        .contact-name {
          @apply font-medium text-slate-900 dark:text-white;
        }

        .contact-phone {
          @apply text-sm text-slate-600 dark:text-slate-400;
        }

        .contact-email {
          @apply text-sm text-slate-500 dark:text-slate-500;
        }
      }

      input[type='checkbox'] {
        @apply w-4 h-4 cursor-pointer accent-black-600;
      }
    }

    .loading-trigger {
      @apply p-4 text-center text-slate-500 dark:text-slate-400;

      &.is-loading {
        @apply bg-slate-50 dark:bg-slate-800;
      }
    }
  }

  .selection-summary {
    @apply p-4 text-sm font-medium
           bg-white dark:bg-slate-800
           text-slate-700 dark:text-white
           border-t border-slate-200 dark:border-slate-700;
  }

  .filters-modal {
    @apply p-6;

    .filters-header {
      @apply mb-6;

      h3 {
        @apply text-lg font-medium text-slate-900 dark:text-white;
      }

      .filters-subtitle {
        @apply mt-1 text-sm text-slate-500 dark:text-slate-400;
      }
    }

    .filters-content {
      @apply space-y-4;

      .filter-row {
        @apply flex items-center gap-2;

        select,
        input {
          @apply px-3 py-2 border rounded
             bg-white dark:bg-slate-700
             border-slate-300 dark:border-slate-600
             text-slate-900 dark:text-white;

          &:focus {
            @apply outline-none ring-2 ring-black-500;
          }
        }

        select {
          /* Reduce the horizontal width */
          @apply min-w-[100px] w-auto; /* Adjust this value to your desired size */
        }

        .filter-attribute {
          @apply flex-shrink-0;
          padding-right: 1.5rem;
          width: 230px; /* Override width specifically for attribute dropdown */
        }

        .filter-operator {
          @apply flex-shrink-0;
          padding-right: 1.5rem;
          width: 230px; /* Override width specifically for operator dropdown */
        }

        .filter-value {
          @apply flex-1;
          width: 230px;
        }

        .remove-filter {
          @apply relative top-[-8px];
        }
      }

      .add-filter {
        @apply flex items-center gap-2 px-3 py-2
           text-black-600 dark:text-black-400
           hover:text-black-700 dark:hover:text-black-300;
      }
    }

    .filters-footer {
      @apply flex justify-end gap-3 mt-6;

      .clear-filters {
        @apply px-4 py-2 text-sm
               text-slate-700 dark:text-slate-300
               hover:text-slate-900 dark:hover:text-white;
      }

      .apply-filters {
        @apply px-4 py-2 text-sm text-white rounded
               bg-black-600 hover:bg-black-700
               dark:bg-black-500 dark:hover:bg-black-600;
      }
    }
  }
}
</style>
