<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { OnClickOutside } from '@vueuse/components';
import {
  ARTICLE_TABS,
  CATEGORY_ALL,
  ARTICLE_TABS_OPTIONS,
} from 'dashboard/helper/portalHelper';

import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
  portalMeta: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits([
  'tabChange',
  'localeChange',
  'categoryChange',
  'newArticle',
]);

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

const handleLocaleAction = ({ value }) => {
  emit('localeChange', value);
  isLocaleMenuOpen.value = false;
};

const handleCategoryAction = ({ value }) => {
  emit('categoryChange', value);
  isCategoryMenuOpen.value = false;
};

const handleNewArticle = () => {
  emit('newArticle');
};

const handleTabChange = value => {
  emit('tabChange', value);
};
</script>

<template>
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
              @action="handleLocaleAction"
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
              @action="handleCategoryAction"
            />
          </OnClickOutside>
        </div>
      </div>
      <Button
        :label="t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.NEW_ARTICLE')"
        icon="add"
        size="sm"
        @click="handleNewArticle"
      />
    </div>
  </div>
</template>
