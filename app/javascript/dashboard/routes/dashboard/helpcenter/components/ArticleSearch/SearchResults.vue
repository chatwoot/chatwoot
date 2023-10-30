<template>
  <div class="flex justify-end gap-1 py-4 bg-white dark:bg-slate-900">
    <div class="flex flex-col gap-1 w-full">
      <woot-loading-state
        v-if="isLoading"
        :message="$t('HELP_CENTER.ARTICLE_SEARCH_RESULT.SEARCH_LOADER')"
      />
      <div v-else-if="showNoResults" class="empty-state-message">
        {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.NO_RESULT') }}
      </div>
      <search-result-item
        v-for="article in articles"
        v-else
        :id="article.id"
        :key="article.id"
        :title="article.title"
        :body="article.content"
        :url="article.url"
        :category="article.category.name"
        :locale="article.category.locale"
        @preview="handlePreview"
        @insert="handleInsert"
      />
    </div>
  </div>
</template>

<script>
import SearchResultItem from 'dashboard/routes/dashboard/helpcenter/components/ArticleSearch/ArticleSearchResultItem.vue';

export default {
  name: 'SearchResults',
  components: {
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
    portalSlug: {
      type: String,
      required: true,
    },
  },
  computed: {
    showNoResults() {
      return this.searchQuery && this.articles.length === 0;
    },
  },
  methods: {
    handlePreview(id) {
      this.$emit('preview', id);
    },
    handleInsert(id) {
      this.$emit('insert', id);
    },
  },
};
</script>
<style scoped>
.empty-state-message {
  @apply text-center flex items-center justify-center px-4 py-8 text-slate-500 text-sm;
}
</style>
