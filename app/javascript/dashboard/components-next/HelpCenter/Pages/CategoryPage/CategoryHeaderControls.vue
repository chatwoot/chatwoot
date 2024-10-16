<script setup>
import { ref, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  categories: {
    type: Array,
    default: () => [],
  },
  allowedLocales: {
    type: Array,
    default: () => [],
  },
  hasSelectedCategory: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['localeChange', 'newCategory', 'editCategory']);

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const isLocaleMenuOpen = ref(false);

const activeLocale = computed(() => {
  return props.allowedLocales.find(
    locale => locale.code === route.params.locale
  );
});

const activeLocaleName = computed(() => activeLocale.value?.name ?? '');
const activeLocaleCode = computed(() => activeLocale.value?.code ?? '');

const localeMenuItems = computed(() => {
  return props.allowedLocales.map(locale => ({
    label: locale.name,
    value: locale.code,
    action: 'filter',
  }));
});

const selectedCategory = computed(() =>
  props.categories.find(category => category.slug === route.params.categorySlug)
);

const selectedCategoryName = computed(() => {
  return selectedCategory.value?.name;
});

const selectedCategoryCount = computed(
  () => selectedCategory.value?.meta?.articles_count || 0
);

const selectedCategoryEmoji = computed(() => {
  return selectedCategory.value?.icon;
});

const categoriesCount = computed(() => props.categories?.length);

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t(
        'HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.BREADCRUMB.CATEGORY_LOCALE',
        { localeCode: activeLocaleCode.value }
      ),
      link: '#',
    },
  ];
  if (selectedCategory.value) {
    items.push({
      label: t(
        'HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.BREADCRUMB.ACTIVE_CATEGORY',
        {
          categoryName: selectedCategoryName.value,
          categoryCount: selectedCategoryCount.value,
        }
      ),
      emoji: selectedCategoryEmoji.value,
    });
  }
  return items;
});

const handleLocaleAction = ({ value }) => {
  emit('localeChange', value);
  isLocaleMenuOpen.value = false;
};

const handleBreadcrumbClick = () => {
  const { categorySlug, ...otherParams } = route.params;
  router.push({
    name: 'list_categories',
    params: otherParams,
  });
};
</script>

<template>
  <div class="flex items-center justify-between w-full">
    <div v-if="!hasSelectedCategory" class="flex items-center gap-4">
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
      <div class="w-px h-3.5 rounded my-auto bg-slate-75 dark:bg-slate-800" />
      <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
        {{
          t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.CATEGORIES_COUNT', {
            n: categoriesCount,
          })
        }}
      </span>
    </div>
    <Breadcrumb
      v-else
      :items="breadcrumbItems"
      @click="handleBreadcrumbClick"
    />
    <Button
      v-if="!hasSelectedCategory"
      :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.NEW_CATEGORY')"
      icon="add"
      size="sm"
      @click="$emit('newCategory')"
    />
    <div v-else class="relative">
      <Button
        :label="t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_HEADER.EDIT_CATEGORY')"
        variant="secondary"
        size="sm"
        @click="$emit('editCategory')"
      />
    </div>
  </div>
</template>
