<template>
  <div class="container">
    <article-header
      :header-title="headerTitle"
      :count="meta.count"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
    <article-table
      :articles="articles"
      :article-count="articles.length"
      :current-page="Number(meta.currentPage)"
      :total-count="meta.count"
      @on-page-change="onPageChange"
    />
    <div v-if="shouldShowLoader" class="articles--loader">
      <spinner />
      <span>{{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}</span>
    </div>
    <empty-state
      v-else-if="shouldShowEmptyState"
      :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import Spinner from 'shared/components/Spinner.vue';
import ArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/ArticleHeader';
import EmptyState from 'dashboard/components/widgets/EmptyState';
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
    };
  },
  computed: {
    ...mapGetters({
      articles: 'articles/allArticles',
      uiFlags: 'articles/uiFlags',
      meta: 'articles/getMeta',
      isFetching: 'articles/isFetching',
      currentUserId: 'getCurrentUserID',
    }),
    shouldShowEmptyState() {
      return !this.isFetching && !this.articles.length;
    },
    shouldShowLoader() {
      return this.isFetching && !this.articles.length;
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
    status() {
      switch (this.articleType) {
        case 'draft':
          return 0;
        case 'published':
          return 1;
        case 'archived':
          return 2;
        default:
          return undefined;
      }
    },
    author() {
      if (this.articleType === 'mine') {
        return this.currentUserId;
      }
      return null;
    },
  },
  watch: {
    $route() {
      this.pageNumber = 1;
      this.fetchArticles();
    },
  },
  mounted() {
    this.fetchArticles();
  },

  methods: {
    newArticlePage() {
      this.$router.push({ name: 'new_article' });
    },
    fetchArticles() {
      this.$store.dispatch('articles/index', {
        pageNumber: this.pageNumber,
        portalSlug: this.$route.params.portalSlug,
        locale: this.$route.params.locale,
        status: this.status,
        author_id: this.author,
      });
    },
    onPageChange(page) {
      this.fetchArticles({ pageNumber: page });
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
