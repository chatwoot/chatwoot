<template>
  <div
    class="flex flex-col px-4 rounded-md shadow-lg bg-white dark:bg-slate-900 z-1000 w-full max-w-[480px] absolute bottom-[calc(100%+3rem)]"
  >
    <search-header @close="onClose" @search="onSearch" />

    <div
      v-if="!isLoading && !searchQuery"
      class="text-center flex items-center justify-center px-4 py-8 text-slate-600 dark:text-slate-400"
    >
      {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.EMPTY_TEXT') }}
    </div>

    <article-view
      v-if="activeUrl"
      :url="activeUrl"
      @back="onBack"
      @insert="onInsert"
    />
    <search-results-list
      v-else
      :search-query="searchQuery"
      :is-loading="isLoading"
      :articles="searchResults"
      @preview="handlePreview"
      @insert="onInsert"
    />
  </div>
</template>

<script>
import { debounce } from '@chatwoot/utils';

import SearchHeader from './Header';
import SearchResultsList from './SearchResults.vue';
import ArticleView from './ArticleView.vue';
import ArticlesAPI from 'portal/api/article';

export default {
  name: 'ArticleSearchPopover',
  components: {
    SearchHeader,
    SearchResultsList,
    ArticleView,
  },
  props: {},
  data() {
    return {
      searchQuery: '',
      isLoading: false,
      searchResults: [],
      activeUrl: '',
    };
  },
  methods: {
    onSearch(query) {
      this.searchQuery = query;
      this.activeUrl = '';
      this.fetchArticlesByQuery(query);
      debounce(() => {}, 500, true);
    },

    onClose() {
      this.$emit('close');
      this.searchQuery = '';
    },
    async fetchArticlesByQuery(query) {
      try {
        this.isLoading = true;
        this.searchResults = [];
        const { data } = await ArticlesAPI.searchArticles(
          'stone-rat',
          'en',
          query
        );
        this.searchResults = data.payload;
        this.isLoading = true;
      } catch (error) {
        // Show something wrong message
      } finally {
        this.isLoading = false;
      }
    },
    handlePreview(url) {
      this.activeUrl = `${url}?show_plain_layout=true`;
    },
    onBack() {
      this.activeUrl = '';
    },
    onInsert() {
      this.$emit('insert', this.activeUrl);
    },
  },
};
</script>
<style lang="scss" scoped>
.search-link {
  &:hover {
    .search--icon,
    .search--label {
      @apply hover:text-woot-500 dark:hover:text-woot-500;
    }
  }
}
</style>
