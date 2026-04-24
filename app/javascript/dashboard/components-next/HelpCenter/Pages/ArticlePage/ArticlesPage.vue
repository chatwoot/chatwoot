<script setup>
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useConfig } from 'dashboard/composables/useConfig';
import { ARTICLE_TABS, CATEGORY_ALL } from 'dashboard/helper/portalHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAlert } from 'dashboard/composables';
import articlesAPI from 'dashboard/api/helpCenter/articles';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
import ArticleHeaderControls from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleHeaderControls.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ArticleEmptyState from 'dashboard/components-next/HelpCenter/EmptyState/Article/ArticleEmptyState.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import BulkTranslateDialog from './BulkTranslateDialog.vue';

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
  isCategoryArticles: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['pageChange', 'fetchPortal', 'refreshArticles']);

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const isSwitchingPortal = useMapGetter('portals/isSwitchingPortal');
const isFetching = useMapGetter('articles/isFetching');
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const selectedArticleIds = ref(new Set());
const deleteConfirmDialogRef = ref(null);

const { isEnterprise } = useConfig();

const isTranslationAvailable = computed(
  () =>
    isEnterprise &&
    isFeatureEnabledonAccount.value(
      currentAccountId.value,
      FEATURE_FLAGS.CAPTAIN_TASKS
    )
);

const allItems = computed(() => props.articles.map(a => ({ id: a.id })));
const visibleArticleIds = computed(() => props.articles.map(a => a.id));

const selectAllLabel = computed(() => {
  if (!visibleArticleIds.value.length) return '';
  return t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.SELECT_ALL', {
    count: visibleArticleIds.value.length,
  });
});

const selectedCountLabel = computed(() =>
  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.SELECTED_COUNT', {
    count: selectedArticleIds.value.size,
  })
);

const bulkTranslateDialogRef = ref(null);

const hasNoArticles = computed(
  () => !isFetching.value && !props.articles.length
);

const isLoading = computed(() => isFetching.value || isSwitchingPortal.value);

const totalArticlesCount = computed(() => props.meta.allArticlesCount);

const hasNoArticlesInPortal = computed(
  () => totalArticlesCount.value === 0 && !props.isCategoryArticles
);

const shouldShowPaginationFooter = computed(() => {
  return !(isFetching.value || isSwitchingPortal.value || hasNoArticles.value);
});

const updateRoute = newParams => {
  const { portalSlug, locale, tab, categorySlug } = route.params;
  router.push({
    name: 'portals_articles_index',
    params: {
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
  return Number(countMap[tab] || countMap['']);
});

const showArticleHeaderControls = computed(
  () => !props.isCategoryArticles && !isSwitchingPortal.value
);

const showCategoryHeaderControls = computed(
  () => props.isCategoryArticles && !isSwitchingPortal.value
);

const getEmptyStateText = type => {
  if (props.isCategoryArticles) {
    return t(`HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.CATEGORY.${type}`);
  }
  const tabName = route.params.tab?.toUpperCase() || 'ALL';
  return t(`HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.${tabName}.${type}`);
};

const getEmptyStateTitle = computed(() => getEmptyStateText('TITLE'));
const getEmptyStateSubtitle = computed(() => getEmptyStateText('SUBTITLE'));

const handleTabChange = tab =>
  updateRoute({ tab: tab.value === ARTICLE_TABS.ALL ? '' : tab.value });

const handleCategoryAction = value =>
  updateRoute({ categorySlug: value === CATEGORY_ALL ? '' : value });

const handleLocaleAction = value => {
  updateRoute({ locale: value, categorySlug: '' });
  emit('fetchPortal', value);
};
const handlePageChange = page => emit('pageChange', page);

const navigateToNewArticlePage = () => {
  const { categorySlug, locale } = route.params;
  router.push({
    name: 'portals_articles_new',
    params: { categorySlug, locale },
  });
};

const handleToggleSelect = articleId => {
  const newSet = new Set(selectedArticleIds.value);
  if (newSet.has(articleId)) {
    newSet.delete(articleId);
  } else {
    newSet.add(articleId);
  }
  selectedArticleIds.value = newSet;
};

const clearSelection = () => {
  selectedArticleIds.value = new Set();
};

const handleTranslateArticle = articleId => {
  selectedArticleIds.value = new Set([articleId]);
  bulkTranslateDialogRef.value?.dialogRef?.open();
};

const openTranslateDialog = () => {
  bulkTranslateDialogRef.value?.dialogRef?.open();
};

const onBulkActionSuccess = message => {
  useAlert(message);
  clearSelection();
  emit('refreshArticles');
};

const bulkUpdateStatus = async status => {
  try {
    await articlesAPI.bulkUpdateStatus({
      portalSlug: route.params.portalSlug,
      articleIds: [...selectedArticleIds.value],
      status,
    });
    onBulkActionSuccess(
      t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.STATUS_SUCCESS')
    );
  } catch (error) {
    useAlert(
      error?.message || t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.STATUS_ERROR')
    );
  }
};

const confirmBulkDelete = () => {
  deleteConfirmDialogRef.value?.open();
};

const bulkDelete = async () => {
  try {
    await articlesAPI.bulkDelete({
      portalSlug: route.params.portalSlug,
      articleIds: [...selectedArticleIds.value],
    });
    deleteConfirmDialogRef.value?.close();
    onBulkActionSuccess(
      t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_SUCCESS')
    );
  } catch (error) {
    deleteConfirmDialogRef.value?.close();
    useAlert(
      error?.message || t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_ERROR')
    );
  }
};

// Clear selection when articles change (page change, filter change)
watch(
  () => props.articles,
  () => clearSelection()
);
</script>

<template>
  <HelpCenterLayout
    :current-page="Number(meta.currentPage)"
    :total-items="articlesCount"
    :items-per-page="25"
    :header="portalName"
    :show-pagination-footer="shouldShowPaginationFooter"
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
          @new-article="navigateToNewArticlePage"
        />
        <CategoryHeaderControls
          v-else-if="showCategoryHeaderControls"
          :categories="categories"
          :allowed-locales="allowedLocales"
          :has-selected-category="isCategoryArticles"
        />
      </div>
    </template>
    <template #content>
      <div
        v-if="isLoading"
        class="flex items-center justify-center py-10 text-n-slate-11"
      >
        <Spinner />
      </div>
      <template v-else-if="!hasNoArticles">
        <div
          v-if="selectedArticleIds.size > 0"
          class="sticky top-0 z-[5] bg-gradient-to-b from-n-surface-1 from-90% to-transparent pt-1 pb-2"
        >
          <BulkSelectBar
            v-model="selectedArticleIds"
            :all-items="allItems"
            :select-all-label="selectAllLabel"
            :selected-count-label="selectedCountLabel"
            class="py-2 ltr:!pr-3 rtl:!pl-3 justify-between"
          >
            <template #secondary-actions>
              <Button
                sm
                ghost
                slate
                :label="
                  t('HELP_CENTER.ARTICLES_PAGE.BULK_TRANSLATE.CLEAR_SELECTION')
                "
                class="!px-1.5"
                @click="clearSelection"
              />
            </template>
            <template #actions>
              <div class="flex items-center gap-2 ml-auto">
                <Button
                  sm
                  faded
                  slate
                  icon="i-lucide-check"
                  :label="t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.PUBLISH')"
                  class="[&>span:nth-child(2)]:hidden sm:[&>span:nth-child(2)]:inline w-fit"
                  @click="bulkUpdateStatus('published')"
                />
                <Button
                  sm
                  faded
                  slate
                  icon="i-lucide-pencil-line"
                  :label="t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DRAFT')"
                  class="[&>span:nth-child(2)]:hidden sm:[&>span:nth-child(2)]:inline w-fit"
                  @click="bulkUpdateStatus('draft')"
                />
                <Button
                  sm
                  faded
                  slate
                  icon="i-lucide-archive-restore"
                  :label="t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.ARCHIVE')"
                  class="[&>span:nth-child(2)]:hidden sm:[&>span:nth-child(2)]:inline w-fit"
                  @click="bulkUpdateStatus('archived')"
                />
                <Button
                  v-if="isTranslationAvailable"
                  sm
                  faded
                  slate
                  icon="i-lucide-languages"
                  :label="t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.TRANSLATE')"
                  class="[&>span:nth-child(2)]:hidden sm:[&>span:nth-child(2)]:inline w-fit"
                  @click="openTranslateDialog"
                />
                <Button
                  sm
                  faded
                  ruby
                  icon="i-lucide-trash"
                  :label="t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE')"
                  class="!px-1.5 [&>span:nth-child(2)]:hidden"
                  @click="confirmBulkDelete"
                />
              </div>
            </template>
          </BulkSelectBar>
        </div>
        <ArticleList
          :articles="articles"
          :is-category-articles="isCategoryArticles"
          :selected-article-ids="selectedArticleIds"
          class="relative z-0"
          @translate-article="handleTranslateArticle"
          @toggle-select="handleToggleSelect"
        />
      </template>
      <ArticleEmptyState
        v-else
        class="pt-14"
        :title="getEmptyStateTitle"
        :subtitle="getEmptyStateSubtitle"
        :show-button="hasNoArticlesInPortal"
        :button-label="
          t('HELP_CENTER.ARTICLES_PAGE.EMPTY_STATE.ALL.BUTTON_LABEL')
        "
        @click="navigateToNewArticlePage"
      />
    </template>
    <BulkTranslateDialog
      ref="bulkTranslateDialogRef"
      :selected-article-ids="[...selectedArticleIds]"
      :allowed-locales="allowedLocales"
      @translate-started="clearSelection"
    />
    <Dialog
      ref="deleteConfirmDialogRef"
      type="alert"
      :title="
        t(
          'HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM_TITLE',
          selectedArticleIds.size
        )
      "
      :description="
        t(
          'HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM_DESCRIPTION',
          selectedArticleIds.size
        )
      "
      :confirm-button-label="
        t('HELP_CENTER.ARTICLES_PAGE.BULK_ACTIONS.DELETE_CONFIRM')
      "
      @confirm="bulkDelete"
    />
  </HelpCenterLayout>
</template>
