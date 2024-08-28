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
      this.$emit('reloadLocale');
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col w-full max-w-full px-0 py-0 overflow-auto bg-white dark:bg-slate-900"
  >
    <ArticleHeader
      :header-title="headerTitle"
      :count="meta.count"
      :selected-locale="activeLocaleName"
      :all-locales="allowedLocales"
      selected-value="Published"
      class="border-b border-slate-50 dark:border-slate-700"
      @newArticlePage="newArticlePage"
      @changeLocale="onChangeLocale"
    />
    <div
      v-if="isFetching"
      class="flex items-center justify-center px-4 py-6 text-base text-slate-600 dark:text-slate-200"
    >
      <Spinner />
      <span class="text-slate-600 dark:text-slate-200">
        {{ $t('HELP_CENTER.TABLE.LOADING_MESSAGE') }}
      </span>
    </div>
    <EmptyState
      v-else-if="shouldShowEmptyState"
      :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
    />
    <div v-else class="flex flex-1">
      <ArticleTable
        :articles="articles"
        :current-page="Number(meta.currentPage)"
        :total-count="Number(meta.count)"
        @pageChange="onPageChange"
        @reorder="onReorder"
      />
    </div>
  </div>
</template>
