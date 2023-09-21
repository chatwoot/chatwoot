<template>
  <div
    class="flex flex-col px-4 rounded-md shadow-lg bg-white dark:bg-slate-900 z-[1000] w-full max-w-[480px] fixed right-1 -bottom-4 sm:w-[17.5rem] md:w-[18.75rem] lg:w-[19.375rem] xl:w-[20.625rem] 2xl:w-[25rem] h-[calc(100vh-4rem)] overflow-y-auto"
  >
    <search-header
      class="w-full sticky top-0 bg-[inherit]"
      @close="onClose"
      @search="onSearch"
    />

    <div
      v-if="!isLoading && !searchQuery"
      class="text-center text-sm flex items-center justify-center px-4 py-8 text-slate-500 "
    >
      {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.EMPTY_TEXT') }}
    </div>

    <article-view
      v-if="activeId"
      :url="articleViewerUrl"
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
      activeId: '',
      debounceSearch: () => {},
    };
  },
  computed: {
    articleViewerUrl() {
      const article = this.activeArticle(this.activeId);
      if (!article) return undefined;

      return article.url;
    },
  },
  mounted() {
    this.debounceSearch = debounce(this.fetchArticlesByQuery, 500, true);
  },
  methods: {
    generateArticleUrl(article) {
      return `/hc/${article.portal.slug}/articles/${article.slug}?show_plain_layout=true`;
    },
    activeArticle(id) {
      const activeArticle = this.searchResults.find(
        article => article.id === id
      );

      if (!activeArticle || id === '') return undefined;

      const url = this.generateArticleUrl(activeArticle);
      return { ...activeArticle, url };
    },
    onSearch(query) {
      this.searchQuery = query;
      this.activeId = '';
      this.debounceSearch(query);
    },
    onClose() {
      this.$emit('close');
      this.searchQuery = '';
      this.activeId = '';
      this.searchResults = [];
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
    handlePreview(id) {
      this.activeId = id;
    },
    onBack() {
      this.activeId = '';
    },
    onInsert(id) {
      const article = this.activeArticle(id || this.activeId);

      this.$emit('insert', article);
    },
  },
};
</script>
