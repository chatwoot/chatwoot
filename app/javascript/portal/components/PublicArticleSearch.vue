<script>
import SearchSuggestions from './SearchSuggestions.vue';
import PublicSearchInput from './PublicSearchInput.vue';

import ArticlesAPI from '../api/article';

export default {
  components: {
    PublicSearchInput,
    SearchSuggestions,
  },
  emits: ['input', 'blur'],
  data() {
    return {
      searchTerm: '',
      isLoading: false,
      showSearchBox: false,
      searchResults: [],
    };
  },

  computed: {
    portalSlug() {
      return window.portalConfig.portalSlug;
    },
    localeCode() {
      return window.portalConfig.localeCode;
    },
    normalizedSearchTerm() {
      return this.searchTerm.trim();
    },
    shouldShowSearchBox() {
      return this.normalizedSearchTerm !== '' && this.showSearchBox;
    },
    searchTranslations() {
      const { searchTranslations = {} } = window.portalConfig;
      return searchTranslations;
    },
  },

  watch: {
    currentPage() {
      this.clearSearchTerm();
    },
  },

  unmounted() {
    clearTimeout(this.typingTimer);
  },

  methods: {
    onUpdateSearchTerm(value) {
      this.searchTerm = value;
      if (this.typingTimer) {
        clearTimeout(this.typingTimer);
      }

      if (this.normalizedSearchTerm === '') {
        this.searchResults = [];
        this.isLoading = false;
        this.closeSearch();
        return;
      }

      this.openSearch();
      this.isLoading = true;
      this.typingTimer = setTimeout(() => {
        this.fetchArticlesByQuery();
      }, 1000);
    },
    onChange(e) {
      this.$emit('input', e.target.value);
    },
    onBlur(e) {
      this.$emit('blur', e.target.value);
    },
    openSearch() {
      this.showSearchBox = true;
    },
    closeSearch() {
      this.showSearchBox = false;
    },
    clearSearchTerm() {
      this.searchTerm = '';
    },
    async fetchArticlesByQuery() {
      const query = this.normalizedSearchTerm;
      if (!query) {
        this.isLoading = false;
        return;
      }

      try {
        this.isLoading = true;
        this.searchResults = [];
        const { data } = await ArticlesAPI.searchArticles(
          this.portalSlug,
          this.localeCode,
          query
        );
        this.searchResults = data.payload;
      } catch (error) {
        // Show something wrong message
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <div v-on-clickaway="closeSearch" class="relative w-full max-w-5xl my-4">
    <PublicSearchInput
      :search-term="searchTerm"
      :search-placeholder="searchTranslations.searchPlaceholder"
      @update:search-term="onUpdateSearchTerm"
      @focus="openSearch"
    />
    <div
      v-if="shouldShowSearchBox"
      class="absolute w-full top-14"
      @mouseover="openSearch"
    >
      <SearchSuggestions
        :items="searchResults"
        :is-loading="isLoading"
        :search-term="normalizedSearchTerm"
        :empty-placeholder="searchTranslations.emptyPlaceholder"
        :results-title="searchTranslations.resultsTitle"
        :loading-placeholder="searchTranslations.loadingPlaceholder"
      />
    </div>
  </div>
</template>
