<template>
  <div class="container">
    <article-header
      :header-title="headerTitle"
      :count="articleCount"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
    <article-table :articles="articles" :article-count="articles.length" />
    <div v-if="isFetchingArticles" class="articles--loader">
      <spinner />
      <span>{{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}</span>
    </div>
    <empty-state
      v-else-if="!isFetchingArticles && !articles.length"
      :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import Spinner from 'shared/components/Spinner.vue';
import ArticleHeader from 'dashboard/components/helpCenter/Header/ArticleHeader';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import ArticleTable from '../../components/ArticleTable';
export default {
  components: {
    ArticleHeader,
    ArticleTable,
    EmptyState,
    Spinner,
  },
  data() {
    return {
      pageNumber: 1,
      articleCount: 12,
    };
  },
  computed: {
    ...mapGetters({
      articles: 'articles/allArticles',
      uiFlags: 'articles/uiFlags',
      isFetchingArticles: 'articles/isFetchingArticles',
    }),
    showEmptyState() {
      return this.articles.length === 0;
    },
    articleType() {
      return this.$route.path.split('/').pop();
    },
    headerTitle() {
      switch (this.articleType) {
        case 'mine':
          return this.$t('HELP_CENTER.HEADER.TITLES.MINE');
        case 'draft':
          return this.$t('HELP_CENTER.HEADER.TITLES.DRAFT');
        case 'archived':
          return this.$t('HELP_CENTER.HEADER.TITLES.ARCHIVED');
        default:
          return this.$t('HELP_CENTER.HEADER.TITLES.ALL_ARTICLES');
      }
    },
  },
  mounted() {
    this.fetchArticles({ pageNumber: this.pageNumber });
  },
  methods: {
    newArticlePage() {
      this.$router.push({ name: 'new_article' });
    },
    fetchArticles({ pageNumber }) {
      this.$store.dispatch('articles/index', {
        pageNumber,
        portalSlug: this.$route.params.portalSlug,
        locale: this.$route.params.locale,
      });
    },
  },
};
</script>

<style lang="scss" scoped>
.container {
  padding: var(--space-small) var(--space-normal);
  width: 100%;
  .articles--loader {
    align-items: center;
    display: flex;
    font-size: var(--font-size-default);
    justify-content: center;
    padding: var(--space-big);
  }
}
</style>
