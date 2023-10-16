<template>
  <div
    v-on-clickaway="onClose"
    class="flex flex-col px-4 pb-4 rounded-md shadow-md border border-solid border-slate-50 dark:border-slate-800 bg-white dark:bg-slate-900 z-[1000] max-w-[720px] md:w-[20rem] lg:w-[24rem] xl:w-[28rem] 2xl:w-[32rem] h-[calc(100vh-20rem)] max-h-[40rem] overflow-y-auto"
    @keyup.esc="onClose"
  >
    <search-header
      :title="$t('HELP_CENTER.ARTICLE_SEARCH.TITLE')"
      class="w-full sticky top-0 bg-[inherit]"
      @close="onClose"
      @search="onSearch"
    />

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
      :portal-slug="portalSlug"
      :articles="searchResultsWithUrl"
      @preview="handlePreview"
      @insert="onInsert"
    />
  </div>
</template>

<script>
import { debounce } from '@chatwoot/utils';
import { mixin as clickaway } from 'vue-clickaway';

import SearchHeader from './Header';
import SearchResultsList from './SearchResults.vue';
import ArticleView from './ArticleView.vue';
import ArticlesAPI from 'dashboard/api/helpCenter/articles';

export default {
  name: 'ArticleSearchPopover',
  components: {
    SearchHeader,
    SearchResultsList,
    ArticleView,
  },
  mixins: [clickaway],
  props: {
    portalSlug: {
      type: String,
      required: true,
    },
  },
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

      return `${article.url}?show_plain_layout=true`;
    },
    searchResultsWithUrl() {
      return this.searchResults.map(article => ({
        ...article,
        url: this.generateArticleUrl(article),
      }));
    },
  },
  mounted() {
    // Load popular articles on mount
    this.fetchArticlesByQuery(this.searchQuery);
    this.debounceSearch = debounce(this.fetchArticlesByQuery, 500, true);
  },
  methods: {
    generateArticleUrl(article) {
      const host =
        window.chatwootConfig.helpCenterURL || window.chatwootConfig.hostURL;
      return `${host}/hc/${this.portalSlug}/articles/${article.slug}`;
    },
    activeArticle(id) {
      return this.searchResultsWithUrl.find(article => article.id === id);
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
        const sort = query ? undefined : 'views';
        this.isLoading = true;
        this.searchResults = [];
        const { data } = await ArticlesAPI.searchArticles({
          portalSlug: this.portalSlug,
          query,
          sort,
        });
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
