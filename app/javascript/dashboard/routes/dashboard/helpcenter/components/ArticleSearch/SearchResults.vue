<template>
  <div class="flex justify-end gap-1 py-6 bg-white dark:bg-slate-900">
    <div class="flex flex-col gap-4 w-full">
      <div
        v-if="isLoading"
        class="text-center flex items-center justify-center px-4 py-8 text-slate-600 dark:text-slate-400"
      >
        <spinner size="" />
        {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.SEARCH_LOADER') }}
      </div>
      <div
        v-else-if="articles.length === 0 && searchQuery"
        class="text-center flex items-center justify-center px-4 py-8 text-slate-600 dark:text-slate-400"
      >
        {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.NO_RESULT') }}
      </div>
      <search-result-item
        v-for="article in articles"
        v-else
        :key="article.id"
        :title="article.title"
        :body="article.content"
        :url="generateArticleUrl(article)"
        :category="article.category.name"
        :locale="article.locale"
        @preview="handlePreview"
        @insert="handleInsert"
      />
    </div>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner';
import SearchResultItem from 'dashboard/routes/dashboard/helpcenter/components/ArticleSearch/ArticleSearchResultItem.vue';

export default {
  name: 'SearchResults',
  components: {
    Spinner,
    SearchResultItem,
  },
  props: {
    articles: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    searchQuery: {
      type: String,
      default: '',
    },
  },
  methods: {
    generateArticleUrl(article) {
      return `/hc/${article.portal.slug}/articles/${article.slug}`;
    },
    handlePreview(url) {
      this.$emit('preview', url);
    },
    handleInsert(url) {
      this.$emit('insert', url);
    },
  },
};
</script>
