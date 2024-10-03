<script>
import SearchResultItem from './ArticleSearchResultItem.vue';

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
  },
  emits: ['preview', 'insert'],
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

<template>
  <div
    class="flex justify-end h-full gap-1 py-4 overflow-y-auto bg-white dark:bg-slate-900"
  >
    <div class="flex flex-col w-full gap-1">
      <div v-if="isLoading" class="empty-state-message">
        {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.SEARCH_LOADER') }}
      </div>
      <div v-else-if="showNoResults" class="empty-state-message">
        {{ $t('HELP_CENTER.ARTICLE_SEARCH_RESULT.NO_RESULT') }}
      </div>
      <template v-else>
        <SearchResultItem
          v-for="article in articles"
          :id="article.id"
          :key="article.id"
          :title="article.title"
          :body="article.content"
          :url="article.url"
          :category="article.category.name"
          :locale="article.localeName"
          @preview="handlePreview"
          @insert="handleInsert"
        />
      </template>
    </div>
  </div>
</template>

<style scoped>
.empty-state-message {
  @apply text-center flex items-center justify-center px-4 py-8 text-slate-500 text-sm;
}
</style>
