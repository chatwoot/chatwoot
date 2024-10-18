<script setup>
import { computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { ARTICLE_TABS, CATEGORY_ALL } from 'dashboard/helper/portalHelper';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
import ArticleHeaderControls from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleHeaderControls.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ArticleEmptyState from 'dashboard/components-next/HelpCenter/EmptyState/Article/ArticleEmptyState.vue';

const props = defineProps({
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
  portalName: {
    type: String,
    required: true,
  },
  meta: {
    type: Object,
    required: true,
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
  hasNoArticles: {
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

const isEmptyAllTab = computed(() => !route.params.tab && props.hasNoArticles);
const isEmptySpecificTab = computed(
  () =>
    [ARTICLE_TABS.MINE, ARTICLE_TABS.DRAFT, ARTICLE_TABS.ARCHIVED].includes(
      route.params.tab
    ) && props.hasNoArticles
);

const showEmptyState = computed(
  () =>
    isEmptyAllTab.value ||
    isEmptySpecificTab.value ||
    (props.isCategoryArticles && props.hasNoArticles)
);

const updateRoute = newParams => {
  const { accountId, portalSlug, locale, tab, categorySlug } = route.params;
  router.push({
    name: 'portals_articles_index',
    params: {
      accountId,
      portalSlug,
      locale: newParams.locale ?? locale,
      tab: newParams.tab ?? tab,
      categorySlug: newParams.categorySlug ?? categorySlug,
      ...newParams,
    },
  });
};

const articlesCount = computed(() => {
  const { tab } = route.params;
  const { meta } = props;
  const countMap = {
    '': meta.articlesCount,
    mine: meta.mineArticlesCount,
    draft: meta.draftArticlesCount,
    archived: meta.archivedArticlesCount,
  };
  return Number(countMap[tab || '']);
});

const showArticleHeaderControls = computed(() => {
  return (
    !props.isCategoryArticles &&
    !isEmptyAllTab.value &&
    (props.meta.articlesCount > 0 ||
      (props.isFetching && articlesCount.value > 0))
  );
});

const getEmptyStateText = type => {
  const tabName = route.params.tab?.toUpperCase() || 'ALL';
  return t(`HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.${tabName}.${type}`);
};

const getEmptyStateTitle = computed(() => {
  if (props.isCategoryArticles) {
    return t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.CATEGORY.TITLE');
  }
  return isEmptySpecificTab.value
    ? getEmptyStateText('TITLE')
    : t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.ALL.TITLE');
});

const getEmptyStateSubtitle = computed(() => {
  if (props.isCategoryArticles) {
    return t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.CATEGORY.SUBTITLE');
  }
  return isEmptySpecificTab.value
    ? getEmptyStateText('SUBTITLE')
    : t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.ALL.SUBTITLE');
});

const handleTabChange = tab =>
  updateRoute({ tab: tab.value === ARTICLE_TABS.ALL ? '' : tab.value });
const handleCategoryAction = value =>
  updateRoute({ categorySlug: value === CATEGORY_ALL ? '' : value });
const handleLocaleAction = value => {
  updateRoute({ locale: value, categorySlug: '' });
  emit('fetchPortal', value);
};
const handlePageChange = page => emit('pageChange', page);
const newArticlePage = () => router.push({ name: 'portals_articles_new' });
</script>

<template>
  <HelpCenterLayout
    :current-page="Number(meta.currentPage)"
    :total-items="articlesCount"
    :items-per-page="25"
    :header="portalName"
    :show-pagination-footer="!isFetching && !hasNoArticles"
    @update:current-page="handlePageChange"
  >
    <template #header-actions>
      <div class="flex items-end justify-between">
        <ArticleHeaderControls
          v-if="showArticleHeaderControls"
          :categories="categories"
          :allowed-locales="allowedLocales"
          :meta="meta"
          @tab-change="handleTabChange"
          @locale-change="handleLocaleAction"
          @category-change="handleCategoryAction"
          @new-article="newArticlePage"
        />
        <CategoryHeaderControls
          v-else-if="!isEmptySpecificTab && isCategoryArticles"
          :categories="categories"
          :allowed-locales="allowedLocales"
          :has-selected-category="isCategoryArticles"
        />
      </div>
    </template>
    <template #content>
      <div
        v-if="isFetching"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <ArticleEmptyState
        v-else-if="showEmptyState"
        class="pt-14"
        :title="getEmptyStateTitle"
        :subtitle="getEmptyStateSubtitle"
        :show-button="isEmptyAllTab && !isCategoryArticles"
        :button-label="
          isEmptyAllTab
            ? t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.ALL.BUTTON_LABEL')
            : ''
        "
        @click="newArticlePage"
      />
      <ArticleList
        v-else
        :articles="articles"
        :is-category-articles="isCategoryArticles"
      />
    </template>
  </HelpCenterLayout>
</template>
