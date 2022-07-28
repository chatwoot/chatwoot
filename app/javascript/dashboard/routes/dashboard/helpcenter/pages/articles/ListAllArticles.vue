<template>
  <div class="container">
    <article-header
      :header-title="headerTitle"
      :count="articleCount"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
    <article-table
      :articles="articlesList"
      :article-count="articlesList.length"
    />
    <div v-if="isFetchingArticles" class="articles--loader">
      <spinner />
      <span>{{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}</span>
    </div>
    <empty-state
      v-else-if="!isFetchingArticles && !articlesList.length"
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
      mineArticles: 'articles/getMineArticles',
      draftArticles: 'articles/getDraftArticles',
      archivedArticles: 'articles/getArchivedArticles',
      uiFlags: 'articles/uiFlags',
      isFetchingArticles: 'articles/isFetchingArticles',
    }),
    articlesList() {
      if (this.articleType === 'mine') {
        return this.mineArticles;
      }
      if (this.articleType === 'draft') {
        return this.draftArticles;
      }
      if (this.articleType === 'archived') {
        return this.archivedArticles;
      }
      return this.articles;
    },
    showEmptyState() {
      return this.articlesList.length === 0;
    },
    articleCount() {
      return this.articlesList.length;
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
