<template>
  <woot-modal
    :show.sync="showModal" 
    :on-close="onClose"
    size="xxl"
    class="advanced-search-modal"
  >
    <template #header>
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-3">
          <fluent-icon icon="search" size="20" />
          <h3 class="text-lg font-semibold">
            {{ $t('ADVANCED_SEARCH.MODAL.TITLE') }}
          </h3>
        </div>
        <div class="flex items-center space-x-2">
          <span 
            v-if="searchResults?.meta?.execution_time"
            class="text-sm text-slate-500"
          >
            {{ searchResults.meta.execution_time }}ms
          </span>
          <woot-button
            v-if="hasActiveSearch"
            size="small"
            variant="clear"
            color-scheme="secondary"
            icon="bookmark"
            @click="showSaveSearchModal = true"
          >
            {{ $t('ADVANCED_SEARCH.SAVE_SEARCH') }}
          </woot-button>
        </div>
      </div>
    </template>

    <template #body>
      <div class="advanced-search-container">
        <!-- Search Input and Filters -->
        <div class="search-header mb-6">
          <AdvancedSearchFilters
            v-model="searchParams"
            :loading="isLoading"
            @search="performSearch"
            @clear="clearSearch"
          />
        </div>

        <!-- Saved Searches -->
        <div v-if="savedSearches.length > 0 && !hasActiveSearch" class="saved-searches mb-6">
          <h4 class="text-sm font-medium mb-3">{{ $t('ADVANCED_SEARCH.SAVED_SEARCHES') }}</h4>
          <div class="flex flex-wrap gap-2">
            <woot-button
              v-for="search in savedSearches.slice(0, 5)"
              :key="search.id"
              size="small"
              variant="smooth"
              color-scheme="secondary"
              @click="loadSavedSearch(search)"
            >
              {{ search.name }}
            </woot-button>
          </div>
        </div>

        <!-- Search Results -->
        <div v-if="hasActiveSearch" class="search-results">
          <!-- Results Summary -->
          <div class="results-summary mb-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <span class="text-sm text-slate-600">
                  {{ formatResultsCount() }}
                </span>
                <div v-if="searchResults?.applied_filters" class="flex items-center space-x-2">
                  <fluent-icon icon="filter" size="16" class="text-slate-400" />
                  <span class="text-sm text-slate-500">
                    {{ Object.keys(searchResults.applied_filters).length }} filters
                  </span>
                </div>
              </div>
              <div class="search-type-tabs">
                <woot-tabs 
                  :tabs="searchTypeTabs" 
                  :active-tab="activeSearchType"
                  @tab-change="changeSearchType"
                />
              </div>
            </div>
          </div>

          <!-- Loading State -->
          <div v-if="isLoading" class="loading-container">
            <woot-loading-state />
          </div>

          <!-- Results Content -->
          <div v-else-if="searchResults" class="results-content">
            <AdvancedSearchResults 
              :results="searchResults.results"
              :search-type="activeSearchType"
              :meta="searchResults.meta"
              @load-more="loadMoreResults"
              @conversation-select="onConversationSelect"
              @contact-select="onContactSelect"
            />
          </div>

          <!-- No Results -->
          <div v-else-if="!isLoading && hasSearched" class="no-results">
            <woot-empty-state 
              :title="$t('ADVANCED_SEARCH.NO_RESULTS.TITLE')"
              :message="$t('ADVANCED_SEARCH.NO_RESULTS.MESSAGE')"
            />
            <!-- Search Suggestions -->
            <div v-if="searchSuggestions?.length > 0" class="suggestions mt-4">
              <h4 class="text-sm font-medium mb-2">{{ $t('ADVANCED_SEARCH.SUGGESTIONS') }}</h4>
              <div class="flex flex-wrap gap-2">
                <woot-button
                  v-for="suggestion in searchSuggestions"
                  :key="suggestion.text"
                  size="small"
                  variant="smooth"
                  @click="applySuggestion(suggestion)"
                >
                  {{ suggestion.text }}
                  <span class="text-xs text-slate-400 ml-1">{{ suggestion.subtitle }}</span>
                </woot-button>
              </div>
            </div>
          </div>
        </div>

        <!-- Initial State -->
        <div v-else class="initial-state">
          <woot-empty-state 
            :title="$t('ADVANCED_SEARCH.INITIAL.TITLE')"
            :message="$t('ADVANCED_SEARCH.INITIAL.MESSAGE')"
            icon="search"
          />
        </div>
      </div>
    </template>

    <!-- Save Search Modal -->
    <SaveSearchModal
      :show="showSaveSearchModal"
      :search-params="searchParams"
      :search-type="activeSearchType"
      @close="showSaveSearchModal = false"
      @saved="onSearchSaved"
    />
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import AdvancedSearchFilters from './AdvancedSearchFilters.vue';
import AdvancedSearchResults from './AdvancedSearchResults.vue';
import SaveSearchModal from './SaveSearchModal.vue';
import AdvancedSearchAPI from '../../api/advancedSearch';

export default {
  name: 'AdvancedSearchModal',
  components: {
    AdvancedSearchFilters,
    AdvancedSearchResults, 
    SaveSearchModal
  },
  props: {
    show: {
      type: Boolean,
      default: false
    },
    initialQuery: {
      type: String,
      default: ''
    },
    initialType: {
      type: String,
      default: 'all'
    }
  },
  emits: ['close', 'conversation-select', 'contact-select'],
  data() {
    return {
      showModal: this.show,
      showSaveSearchModal: false,
      isLoading: false,
      hasSearched: false,
      activeSearchType: this.initialType,
      searchParams: {
        query: this.initialQuery,
        channel_types: [],
        inbox_ids: [],
        agent_ids: [],
        team_ids: [],
        tags: [],
        labels: [],
        status: [],
        priority: [],
        message_types: [],
        sender_types: [],
        sentiment: [],
        sla_status: [],
        date_from: null,
        date_to: null,
        has_attachments: false,
        unread_only: false,
        assigned_only: false,
        unassigned_only: false
      },
      searchResults: null,
      searchSuggestions: [],
      savedSearches: []
    };
  },
  computed: {
    ...mapGetters({
      currentAccount: 'getCurrentAccount'
    }),
    hasActiveSearch() {
      return this.searchParams.query || this.hasActiveFilters();
    },
    searchTypeTabs() {
      if (!this.searchResults) return [];
      
      const tabs = [
        { key: 'all', name: this.$t('ADVANCED_SEARCH.TYPES.ALL') },
        { key: 'conversations', name: this.$t('ADVANCED_SEARCH.TYPES.CONVERSATIONS') },
        { key: 'messages', name: this.$t('ADVANCED_SEARCH.TYPES.MESSAGES') },
        { key: 'contacts', name: this.$t('ADVANCED_SEARCH.TYPES.CONTACTS') }
      ];

      // Add result counts to tab names
      return tabs.map(tab => ({
        ...tab,
        count: this.getResultCount(tab.key)
      }));
    }
  },
  watch: {
    show: {
      handler(newValue) {
        this.showModal = newValue;
        if (newValue) {
          this.loadSavedSearches();
        }
      },
      immediate: true
    },
    showModal(newValue) {
      if (!newValue) {
        this.$emit('close');
      }
    }
  },
  mounted() {
    // Initialize search if query provided
    if (this.initialQuery) {
      this.performSearch();
    }
  },
  methods: {
    async performSearch() {
      if (!this.hasActiveSearch) return;

      this.isLoading = true;
      this.hasSearched = true;

      try {
        const params = this.buildSearchParams();
        let response;

        switch (this.activeSearchType) {
          case 'conversations':
            response = await AdvancedSearchAPI.conversations(params);
            break;
          case 'messages':
            response = await AdvancedSearchAPI.messages(params);
            break;
          case 'contacts':
            response = await AdvancedSearchAPI.contacts(params);
            break;
          default:
            response = await AdvancedSearchAPI.search(params);
        }

        this.searchResults = response.data;
        this.searchSuggestions = response.data.suggestions || [];

        // Track search performance
        if (response.data.meta?.execution_time > 300) {
          console.warn(`Slow search detected: ${response.data.meta.execution_time}ms`);
        }

      } catch (error) {
        console.error('Search failed:', error);
        this.showAlert('Search failed. Please try again.');
      } finally {
        this.isLoading = false;
      }
    },

    async loadMoreResults() {
      if (!this.searchResults?.meta?.page) return;

      const nextPage = this.searchResults.meta.page + 1;
      const params = { ...this.buildSearchParams(), page: nextPage };

      try {
        let response;
        switch (this.activeSearchType) {
          case 'conversations':
            response = await AdvancedSearchAPI.conversations(params);
            break;
          case 'messages':
            response = await AdvancedSearchAPI.messages(params);
            break;
          case 'contacts':
            response = await AdvancedSearchAPI.contacts(params);
            break;
          default:
            response = await AdvancedSearchAPI.search(params);
        }

        // Append new results
        const newResults = response.data.results;
        Object.keys(newResults).forEach(key => {
          if (this.searchResults.results[key]) {
            this.searchResults.results[key].push(...newResults[key]);
          }
        });

        this.searchResults.meta = response.data.meta;
      } catch (error) {
        console.error('Failed to load more results:', error);
      }
    },

    buildSearchParams() {
      const params = { ...this.searchParams };
      
      // Clean up empty arrays and null values
      Object.keys(params).forEach(key => {
        if (Array.isArray(params[key]) && params[key].length === 0) {
          delete params[key];
        } else if (params[key] === null || params[key] === '') {
          delete params[key];
        }
      });

      return params;
    },

    hasActiveFilters() {
      const filterKeys = [
        'channel_types', 'inbox_ids', 'agent_ids', 'team_ids', 'tags', 'labels',
        'status', 'priority', 'message_types', 'sender_types', 'sentiment', 'sla_status'
      ];
      
      return filterKeys.some(key => 
        Array.isArray(this.searchParams[key]) && this.searchParams[key].length > 0
      ) || this.searchParams.date_from || this.searchParams.date_to ||
      this.searchParams.has_attachments || this.searchParams.unread_only ||
      this.searchParams.assigned_only || this.searchParams.unassigned_only;
    },

    changeSearchType(newType) {
      this.activeSearchType = newType;
      this.performSearch();
    },

    clearSearch() {
      this.searchParams = {
        query: '',
        channel_types: [],
        inbox_ids: [],
        agent_ids: [],
        team_ids: [],
        tags: [],
        labels: [],
        status: [],
        priority: [],
        message_types: [],
        sender_types: [],
        sentiment: [],
        sla_status: [],
        date_from: null,
        date_to: null,
        has_attachments: false,
        unread_only: false,
        assigned_only: false,
        unassigned_only: false
      };
      this.searchResults = null;
      this.hasSearched = false;
      this.searchSuggestions = [];
    },

    applySuggestion(suggestion) {
      switch (suggestion.type) {
        case 'contact':
          this.searchParams.query = suggestion.text;
          break;
        case 'label':
          this.searchParams.labels.push(suggestion.text);
          break;
        case 'agent':
          // Would need to map name to ID
          this.searchParams.query = suggestion.text;
          break;
        default:
          this.searchParams.query = suggestion.text;
      }
      this.performSearch();
    },

    async loadSavedSearches() {
      try {
        const response = await AdvancedSearchAPI.getSavedSearches();
        this.savedSearches = response.data.saved_searches || [];
      } catch (error) {
        console.error('Failed to load saved searches:', error);
      }
    },

    loadSavedSearch(search) {
      this.searchParams = {
        ...this.searchParams,
        ...search.formatted_filters,
        query: search.query || ''
      };
      this.activeSearchType = search.search_type;
      this.performSearch();

      // Track usage
      AdvancedSearchAPI.incrementSearchUsage(search.id).catch(console.error);
    },

    formatResultsCount() {
      if (!this.searchResults?.meta?.total_results) {
        return this.$t('ADVANCED_SEARCH.NO_RESULTS_COUNT');
      }

      const count = this.searchResults.meta.total_results;
      if (count === 1) {
        return this.$t('ADVANCED_SEARCH.ONE_RESULT');
      }
      
      return this.$t('ADVANCED_SEARCH.RESULTS_COUNT', { count });
    },

    getResultCount(type) {
      if (!this.searchResults?.results) return 0;

      switch (type) {
        case 'all':
          return this.searchResults.meta?.total_results || 0;
        case 'conversations':
          return this.searchResults.results.conversations?.length || 0;
        case 'messages':
          return this.searchResults.results.messages?.length || 0;
        case 'contacts':
          return this.searchResults.results.contacts?.length || 0;
        default:
          return 0;
      }
    },

    onConversationSelect(conversation) {
      this.$emit('conversation-select', conversation);
      this.onClose();
    },

    onContactSelect(contact) {
      this.$emit('contact-select', contact);
      this.onClose();
    },

    onSearchSaved(savedSearch) {
      this.savedSearches.unshift(savedSearch);
      this.showSaveSearchModal = false;
      this.showAlert('Search saved successfully!', 'success');
    },

    onClose() {
      this.showModal = false;
    },

    showAlert(message, type = 'error') {
      // Implement alert system
      console.log(`Alert (${type}): ${message}`);
    }
  }
};
</script>

<style lang="scss" scoped>
.advanced-search-modal {
  .search-header {
    border-bottom: 1px solid theme('colors.slate.200');
    padding-bottom: 1rem;
  }

  .results-summary {
    border-bottom: 1px solid theme('colors.slate.100');
    padding-bottom: 1rem;
  }

  .results-content {
    max-height: 60vh;
    overflow-y: auto;
  }

  .loading-container {
    display: flex;
    justify-content: center;
    padding: 2rem;
  }

  .saved-searches {
    background: theme('colors.slate.50');
    border-radius: 0.5rem;
    padding: 1rem;
  }

  .suggestions {
    background: theme('colors.blue.50');
    border-radius: 0.5rem;
    padding: 1rem;
  }
}
</style>