<script setup>
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import CategoryList from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryList.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
import EditCategoryDialog from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/EditCategoryDialog.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
  allowedLocales: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['fetchCategories']);

const route = useRoute();
const router = useRouter();
const store = useStore();
const { t } = useI18n();

const editCategoryDialog = ref(null);
const selectedCategory = ref(null);

const updateRoute = (newParams, routeName) => {
  const { accountId, portalSlug, locale } = route.params;
  const baseParams = { accountId, portalSlug, locale };

  router.push({
    name: routeName,
    params: {
      ...baseParams,
      ...newParams,
      categorySlug: newParams.categorySlug,
    },
  });
};

const openCategoryArticles = slug => {
  updateRoute({ categorySlug: slug }, 'list_category_articles');
};

const handleLocaleChange = value => {
  updateRoute({ locale: value }, 'list_categories');
  emit('fetchCategories', value);
};

async function deleteCategory(category) {
  try {
    await store.dispatch('categories/delete', {
      portalSlug: route.params.portalSlug,
      categoryId: category.id,
    });

    useTrack(PORTALS_EVENTS.DELETE_CATEGORY, {
      hasArticles: category?.meta?.articles_count > 0,
    });

    useAlert(
      t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.DELETE.API.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      error.message ||
        t('HELP_CENTER.CATEGORY_PAGE.CATEGORY_DIALOG.DELETE.API.ERROR_MESSAGE')
    );
  }
}

const handleAction = ({ action, id, category: categoryData }) => {
  if (action === 'edit') {
    selectedCategory.value = props.categories.find(
      category => category.id === id
    );
    editCategoryDialog.value.dialogRef.open();
  }
  if (action === 'delete') {
    deleteCategory(categoryData);
  }
};
</script>

<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <CategoryHeaderControls
        :categories="categories"
        :is-category-articles="false"
        :allowed-locales="allowedLocales"
        @locale-change="handleLocaleChange"
      />
    </template>
    <template #content>
      <CategoryList
        :categories="categories"
        @click="openCategoryArticles"
        @action="handleAction"
      />
    </template>
    <EditCategoryDialog
      ref="editCategoryDialog"
      :allowed-locales="allowedLocales"
      :selected-category="selectedCategory"
    />
  </HelpCenterLayout>
</template>
