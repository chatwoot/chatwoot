<template>
  <div v-on-clickaway="closeSearch" class="max-w-5xl w-full relative my-4">
    <public-search-input
      v-model="searchTerm"
      :search-placeholder="searchTranslations.searchPlaceholder"
      @focus="openSearch"
    />
    <div
      v-if="shouldShowSearchBox"
      class="absolute top-14 w-full"
      @mouseover="openSearch"
    >
      <search-suggestions
        :items="searchResults"
        :is-loading="isLoading"
        :search-term="searchTerm"
        :empty-placeholder="searchTranslations.emptyPlaceholder"
        :results-title="searchTranslations.resultsTitle"
        :loading-placeholder="searchTranslations.loadingPlaceholder"
      />
    </div>
  </div>
</template>

<script>
import SearchSuggestions from './SearchSuggestions.vue';
import PublicSearchInput from './PublicSearchInput.vue';

import ArticlesAPI from '../api/article';

export default {
  components: {
    PublicSearchInput,
    SearchSuggestions,
  },
  props: {
    value: {
      type: [String, Number],
      default: '',
    },
  },
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
    shouldShowSearchBox() {
      return this.searchTerm !== '' && this.showSearchBox;
    },
    searchTranslations() {
      const { searchTranslations = {} } = window.portalConfig;
      return searchTranslations;
    },
  },

  watch: {
    searchTerm() {
      if (this.typingTimer) {
        clearTimeout(this.typingTimer);
      }

      this.openSearch();
      this.isLoading = true;
      this.typingTimer = setTimeout(() => {
        this.fetchArticlesByQuery();
      }, 1000);
    },
    currentPage() {
      this.clearSearchTerm();
    },
  },

  beforeDestroy() {
    clearTimeout(this.typingTimer);
  },

  methods: {
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
      try {
        this.isLoading = true;
        this.searchResults = [];
        const { data } = await ArticlesAPI.searchArticles(
          this.portalSlug,
          this.localeCode,
          this.searchTerm
        );
        this.searchResults = data.payload;
        this.isLoading = true;
      } catch (error) {
        // Show something wrong message
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
