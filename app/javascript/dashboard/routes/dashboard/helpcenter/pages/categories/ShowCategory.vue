<template>
  <div class="container">
    <article-header
      :header-title="headerTitle"
      :count="articleCountBasedOnCategory"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
    <article-table
      :articles="articlesBasedOnCategory"
      :article-count="articlesBasedOnCategory.length"
      :current-page="Number(meta.currentPage)"
      :total-count="articleCountBasedOnCategory"
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

import ArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/ArticleHeader';
import EmptyState from 'dashboard/components/widgets/EmptyState';
import Spinner from 'shared/components/Spinner.vue';
import ArticleTable from 'dashboard/routes/dashboard/helpcenter/components/ArticleTable';
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
      categories: 'categories/allCategories',
      uiFlags: 'articles/uiFlags',
      meta: 'articles/getMeta',
      isFetching: 'articles/isFetching',
    }),
    shouldShowEmptyState() {
      return !this.isFetching && this.articlesBasedOnCategory.length === 0;
    },
    shouldShowLoader() {
      return this.isFetching && this.articlesBasedOnCategory.length === 0;
    },
    selectedCategorySlug() {
      const { categorySlug } = this.$route.params;
      return categorySlug;
    },
    headerTitle() {
      return this.categories.length ? this.selectedCategory.name : '';
    },
    selectedCategory() {
      return this.categories.find(
        category => category.slug === this.selectedCategorySlug
      );
    },
    selectedCategoryId() {
      return this.categories.length ? this.selectedCategory.id : null;
    },
    articlesBasedOnCategory() {
      return this.articles.filter(article => {
        return (
          article.category && article.category.id === this.selectedCategoryId
        );
      });
    },
    articleCountBasedOnCategory() {
      return this.categories.length
        ? this.selectedCategory.meta.articles_count
        : 0;
    },
  },
  watch: {
    $route() {
      this.pageNumber = 1;
      this.fetchArticlesAndItsCategories();
    },
  },
  mounted() {
    this.fetchArticlesAndItsCategories();
  },
  methods: {
    newArticlePage() {
      this.$router.push({ name: 'new_article' });
    },
    fetchArticlesAndItsCategories() {
      this.$store
        .dispatch('articles/index', {
          pageNumber: this.pageNumber,
          portalSlug: this.$route.params.portalSlug,
          locale: this.$route.params.locale,
          status: this.status,
          author_id: this.author,
        })
        .then(() => {
          this.$store.dispatch('categories/index', {
            portalSlug: this.selectedPortalSlug,
          });
        });
    },
    onPageChange(page) {
      this.fetchArticlesAndItsCategories({ pageNumber: page });
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
