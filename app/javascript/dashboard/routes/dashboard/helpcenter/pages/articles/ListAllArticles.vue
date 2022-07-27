<template>
  <div class="container">
    <article-header
      :header-title="headerTitle"
      :count="articleCount"
      selected-value="Published"
      @newArticlePage="newArticlePage"
    />
    <article-table :articles="articles" :article-count="articles.length" />
    <empty-state
      v-if="showSearchEmptyState"
      :title="$t('HELP_CENTER.TABLE.404')"
    />
    <empty-state
      v-else-if="!isLoading && !articles.length"
      :title="$t('CONTACTS_PAGE.LIST.NO_CONTACTS')"
    />
    <div v-if="isLoading" class="articles--loader">
      <spinner />
      <span>{{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}</span>
    </div>
  </div>
</template>
<script>
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
      // Dummy data will remove once the state is implemented.
      articles: [
        {
          title: 'Setup your account',
          author: {
            name: 'John Doe',
          },
          readCount: 13,
          category: 'Getting started',
          status: 'published',
          updatedAt: 1657255863,
        },
        {
          title: 'Docker Configuration',
          author: {
            name: 'Sam Manuel',
          },
          readCount: 13,
          category: 'Engineering',
          status: 'draft',
          updatedAt: 1656658046,
        },
        {
          title: 'Campaigns',
          author: {
            name: 'Sam Manuel',
          },
          readCount: 28,
          category: 'Engineering',
          status: 'archived',
          updatedAt: 1657590446,
        },
      ],
      articleCount: 12,
      isLoading: false,
    };
  },
  computed: {
    showSearchEmptyState() {
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
  methods: {
    newArticlePage() {
      this.$router.push({ name: 'new_article' });
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
