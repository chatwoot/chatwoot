<script setup>
import { computed, ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';
import {
  ARTICLE_TABS,
  CATEGORY_ALL,
  ARTICLE_TABS_OPTIONS,
} from 'dashboard/helper/portalHelper';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';

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
});

const emit = defineEmits(['pageChange', 'fetchPortal']);

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const isCategoryMenuOpen = ref(false);
const isLocaleMenuOpen = ref(false);

const tabs = computed(() => {
  return ARTICLE_TABS_OPTIONS.map(tab => ({
    label: t(`HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.TABS.${tab.key}`),
    value: tab.value,
    count: props.portalMeta[`${tab.value}ArticlesCount`],
  }));
});

const activeTabIndex = computed(() => {
  const tabParam = route.params.tab || ARTICLE_TABS.ALL;
  return tabs.value.findIndex(tab => tab.value === tabParam);
});

const activeCategoryName = computed(() => {
  return (
    props.categories.find(
      category => category.slug === route.params.categorySlug
    )?.name ?? t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.CATEGORY.ALL')
  );
});

const activeLocaleName = computed(() => {
  return props.allowedLocales.find(
    locale => locale.code === route.params.locale
  )?.name;
});

const categoryMenuItems = computed(() => {
  const defaultMenuItem = {
    label: t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.CATEGORY.ALL'),
    value: CATEGORY_ALL,
    action: 'filter',
  };

  const categoryItems = props.categories.map(category => ({
    label: category.name,
    value: category.slug,
    action: 'filter',
  }));

  const hasCategorySlug = !!route.params.categorySlug;

  return hasCategorySlug ? [defaultMenuItem, ...categoryItems] : categoryItems;
});

const localeMenuItems = computed(() => {
  return props.allowedLocales.map(locale => ({
    label: locale.name,
    value: locale.code,
    action: 'filter',
  }));
});

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

const handleCategoryAction = ({ value }) => {
  updateRoute({ categorySlug: value === CATEGORY_ALL ? '' : value });
  isCategoryMenuOpen.value = false;
};

const handleLocaleAction = ({ value }) => {
  updateRoute({ locale: value, categorySlug: '' });
  emit('fetchPortal', value);
  isLocaleMenuOpen.value = false;
};

const handlePageChange = page => {
  emit('pageChange', page);
};

const newArticlePage = () => {
  router.push({ name: 'new_article' });
};
</script>

<template>
  <HelpCenterLayout
    :current-page="Number(meta.currentPage)"
    :total-items="Number(meta.count)"
    :items-per-page="25"
    :show-pagination-footer="!isFetching && !shouldShowEmptyState"
    @update:current-page="handlePageChange"
  >
    <template #header-actions>
      <div class="flex items-end justify-between">
        <div class="flex flex-col items-start w-full gap-2 lg:flex-row">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="handleTabChange"
          />
          <div class="flex items-start justify-between w-full gap-2">
            <div class="flex items-center gap-2">
              <div class="relative group">
                <Button
                  :label="activeLocaleName"
                  size="sm"
                  icon-position="right"
                  icon="chevron-lucide-down"
                  icon-lib="lucide"
                  variant="secondary"
                  @click="isLocaleMenuOpen = !isLocaleMenuOpen"
                />
                <OnClickOutside @trigger="isLocaleMenuOpen = false">
                  <DropdownMenu
                    v-if="isLocaleMenuOpen"
                    :menu-items="localeMenuItems"
                    class="left-0 w-40 mt-2 overflow-y-auto xl:right-0 top-full max-h-60"
                    @action="handleLocaleAction($event)"
                  />
                </OnClickOutside>
              </div>
              <div class="relative group">
                <Button
                  :label="activeCategoryName"
                  size="sm"
                  icon-position="right"
                  icon="chevron-lucide-down"
                  icon-lib="lucide"
                  variant="secondary"
                  @click="isCategoryMenuOpen = !isCategoryMenuOpen"
                />
                <OnClickOutside @trigger="isCategoryMenuOpen = false">
                  <DropdownMenu
                    v-if="isCategoryMenuOpen"
                    :menu-items="categoryMenuItems"
                    class="left-0 w-40 mt-2 overflow-y-auto xl:right-0 top-full max-h-60"
                    @action="handleCategoryAction($event)"
                  />
                </OnClickOutside>
              </div>
            </div>
            <Button
              :label="
                t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.NEW_ARTICLE')
              "
              icon="add"
              size="sm"
              @click="newArticlePage"
            />
          </div>
        </div>
      </div>
    </template>
    <template #content>
      <div
        v-if="isFetching"
        class="flex items-center justify-center h-full min-h-full"
      >
        <Spinner />
      </div>
      <EmptyState
        v-else-if="shouldShowEmptyState"
        :title="$t('HELP_CENTER.TABLE.NO_ARTICLES')"
      />
      <ArticleList v-else :articles="articles" :categories="categories" />
    </template>
  </HelpCenterLayout>
</template>
