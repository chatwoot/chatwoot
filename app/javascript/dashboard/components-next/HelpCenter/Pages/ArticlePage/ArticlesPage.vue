<script setup>
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { ARTICLE_TABS, CATEGORY_ALL } from 'dashboard/helper/portalHelper';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
import ArticleHeaderControls from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleHeaderControls.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

defineProps({
  articles: {
    type: Array,
    required: true,
  },
  categories: {
    type: Array,
    required: true,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
  meta: {
    type: Object,
    required: true,
  },
  portalMeta: {
    type: Object,
    required: true,
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  shouldShowEmptyState: {
    type: Boolean,
    default: false,
  },
  isCategoryArticles: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['pageChange', 'fetchPortal']);

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const updateRoute = newParams => {
  const { accountId, portalSlug, locale, tab, categorySlug } = route.params;
  const baseParams = { accountId, portalSlug };

  router.push({
    name: 'list_articles',
    params: {
      ...baseParams,
      ...newParams,
      locale: newParams.locale ?? locale,
      tab: newParams.tab ?? tab,
      categorySlug: newParams.categorySlug ?? categorySlug,
    },
  });
};

const handleTabChange = tab => {
  updateRoute({ tab: tab.value === ARTICLE_TABS.ALL ? '' : tab.value });
};

const handleCategoryAction = value => {
  updateRoute({ categorySlug: value === CATEGORY_ALL ? '' : value });
};

const handleLocaleAction = value => {
  updateRoute({ locale: value, categorySlug: '' });
  emit('fetchPortal', value);
};

const handlePageChange = page => {
  emit('pageChange', page);
};

const newArticlePage = () => {
  router.push({ name: 'new_articles' });
};
</script>

<template>
  <HelpCenterLayout
    :current-page="Number(meta.currentPage)"
    :total-items="Number(meta.articlesCount)"
    :items-per-page="25"
    :show-pagination-footer="!isFetching && !shouldShowEmptyState"
    @update:current-page="handlePageChange"
  >
    <template #header-actions>
      <div class="flex items-end justify-between">
        <ArticleHeaderControls
          v-if="!isCategoryArticles"
          :categories="categories"
          :allowed-locales="allowedLocales"
          :meta="meta"
          @tab-change="handleTabChange"
          @locale-change="handleLocaleAction"
          @category-change="handleCategoryAction"
          @new-article="newArticlePage"
        />
        <CategoryHeaderControls
          v-else
          :categories="categories"
          :allowed-locales="allowedLocales"
          :has-selected-category="isCategoryArticles"
        />
      </div>
    </template>
    <template #content>
      <div v-if="isFetching" class="flex items-center justify-center py-10">
        <Spinner />
      </div>
      <EmptyState
        v-else-if="shouldShowEmptyState"
        :title="t('HELP_CENTER.TABLE.NO_ARTICLES')"
      />
      <ArticleList
        v-else
        :articles="articles"
        :categories="categories"
        :is-category-articles="isCategoryArticles"
      />
    </template>
  </HelpCenterLayout>
</template>
