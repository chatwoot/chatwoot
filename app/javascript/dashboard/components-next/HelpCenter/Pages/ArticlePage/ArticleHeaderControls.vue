<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { OnClickOutside } from '@vueuse/components';
import { useUISettings } from 'dashboard/composables/useUISettings';
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
  meta: {
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
const { updateUISettings } = useUISettings();

const isCategoryMenuOpen = ref(false);
const isLocaleMenuOpen = ref(false);

const countKey = tab => {
  if (tab.value === 'all') {
    return 'articlesCount';
  }
  return `${tab.value}ArticlesCount`;
};

const tabs = computed(() => {
  return ARTICLE_TABS_OPTIONS.map(tab => ({
    label: t(`HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.TABS.${tab.key}`),
    value: tab.value,
    count: props.meta[countKey(tab)],
  }));
});

const activeTabIndex = computed(() => {
  const tabParam = route.params.tab || ARTICLE_TABS.ALL;
  return tabs.value.findIndex(tab => tab.value === tabParam);
});

const activeCategoryName = computed(() => {
  const activeCategory = props.categories.find(
    category => category.slug === route.params.categorySlug
  );

  if (activeCategory) {
    const { icon, name } = activeCategory;
    return `${icon} ${name}`;
  }

  return t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.CATEGORY.ALL');
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
    emoji: category.icon,
  }));

  const hasCategorySlug = !!route.params.categorySlug;

  return hasCategorySlug ? [defaultMenuItem, ...categoryItems] : categoryItems;
});

const hasCategoryMenuItems = computed(() => {
  return categoryMenuItems.value?.length > 0;
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
  updateUISettings({
    last_active_locale_code: value,
  });
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
          <OnClickOutside @trigger="isLocaleMenuOpen = false">
            <Button
              :label="activeLocaleName"
              size="sm"
              icon="i-lucide-chevron-down"
              color="slate"
              trailing-icon
              @click="isLocaleMenuOpen = !isLocaleMenuOpen"
            />

            <DropdownMenu
              v-if="isLocaleMenuOpen"
              :menu-items="localeMenuItems"
              show-search
              class="left-0 w-40 max-w-[300px] mt-2 overflow-y-auto xl:right-0 top-full max-h-60"
              @action="handleLocaleAction"
            />
          </OnClickOutside>
        </div>
        <div v-if="hasCategoryMenuItems" class="relative group">
          <OnClickOutside @trigger="isCategoryMenuOpen = false">
            <Button
              :label="activeCategoryName"
              icon="i-lucide-chevron-down"
              size="sm"
              color="slate"
              trailing-icon
              class="max-w-48"
              @click="isCategoryMenuOpen = !isCategoryMenuOpen"
            />

            <DropdownMenu
              v-if="isCategoryMenuOpen"
              :menu-items="categoryMenuItems"
              show-search
              class="left-0 w-48 mt-2 overflow-y-auto xl:right-0 top-full max-h-60"
              @action="handleCategoryAction"
            />
          </OnClickOutside>
        </div>
      </div>
      <Button
        :label="t('HELP_CENTER.ARTICLES_PAGE.ARTICLES_HEADER.NEW_ARTICLE')"
        icon="i-lucide-plus"
        size="sm"
        @click="handleNewArticle"
      />
    </div>
  </div>
</template>
