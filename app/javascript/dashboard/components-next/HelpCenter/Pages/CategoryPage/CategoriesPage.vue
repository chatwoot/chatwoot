<script setup>
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

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

const handleAction = ({ action, id }) => {
  if (action === 'edit') {
    selectedCategory.value = props.categories.find(
      category => category.id === id
    );
    editCategoryDialog.value.dialogRef.open();
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
      :selected-category="selectedCategory"
    />
  </HelpCenterLayout>
</template>
