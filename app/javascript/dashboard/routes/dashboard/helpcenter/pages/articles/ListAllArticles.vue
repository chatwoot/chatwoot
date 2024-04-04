<template>
  <div
    class="py-0 px-0 w-full max-w-full overflow-auto bg-white dark:bg-slate-900 flex flex-col"
  >
    <article-header
      :header-title="headerTitle"
      :count="meta.count"
      :selected-locale="activeLocaleName"
      :all-locales="allowedLocales"
      selected-value="Published"
      class="border-b border-slate-50 dark:border-slate-700"
      @new-article-page="newArticlePage"
      @change-locale="onChangeLocale"
    />
    <div
      v-if="isFetching"
      class="items-center flex text-base justify-center py-6 px-4 text-slate-600 dark:text-slate-200"
    >
      <spinner />
      <span class="text-slate-600 dark:text-slate-200">
        {{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}
      </span>
    </div>
    <empty-state
      v-else-if="shouldShowEmptyState"
      :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
    />
    <div v-else class="flex flex-1">
      <article-table
        :articles="articles"
        :current-page="Number(meta.currentPage)"
        :total-count="Number(meta.count)"
        @page-change="onPageChange"
        @reorder="onReorder"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import allLocales from 'shared/constants/locales.js';

import Spinner from 'shared/components/Spinner.vue';
import ArticleHeader from 'dashboard/routes/dashboard/helpcenter/components/Header/ArticleHeader.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import ArticleTable from '../../components/ArticleTable.vue';

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
      currentUserId: 'getCurrentUserID',
      getPortalBySlug: 'portals/portalBySlug',
    }),
    selectedCategory() {
      return this.categories.find(
        category => category.slug === this.selectedCategorySlug
      );
    },
    shouldShowEmptyState() {
      return !this.isFetching && !this.articles.length;
    },
    selectedPortalSlug() {
      return this.$route.params.portalSlug;
    },
    selectedCategorySlug() {
      const { categorySlug } = this.$route.params;
      return categorySlug;
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
          if (this.$route.name === 'show_category') {
            return this.headerTitleInCategoryView;
          }
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
    headerTitleInCategoryView() {
      return this.categories && this.categories.length
        ? this.selectedCategory.name
        : '';
    },
    activeLocale() {
      return this.$route.params.locale;
    },
    activeLocaleName() {
      return allLocales[this.activeLocale];
    },
    portal() {
      return this.getPortalBySlug(this.selectedPortalSlug);
    },
    allowedLocales() {
      if (!this.portal) {
        return [];
      }
      const { allowed_locales: allowedLocales } = this.portal.config;
      return allowedLocales.map(locale => {
        return {
          id: locale.code,
          name: allLocales[locale.code],
          code: locale.code,
        };
      });
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
    fetchArticles({ pageNumber } = {}) {
      this.$store.dispatch('articles/index', {
        pageNumber: pageNumber || this.pageNumber,
        portalSlug: this.$route.params.portalSlug,
        locale: this.activeLocale,
        status: this.status,
        authorId: this.author,
        categorySlug: this.selectedCategorySlug,
      });
    },
    onPageChange(pageNumber) {
      this.fetchArticles({ pageNumber });
    },
    onReorder(reorderedGroup) {
      this.$store.dispatch('articles/reorder', {
        reorderedGroup,
        portalSlug: this.$route.params.portalSlug,
      });
    },
    onChangeLocale(locale) {
      this.$router.push({
        name: 'list_all_locale_articles',
        params: {
          portalSlug: this.$route.params.portalSlug,
          locale,
        },
      });
      this.$emit('reload-locale');
    },
  },
};
</script>
