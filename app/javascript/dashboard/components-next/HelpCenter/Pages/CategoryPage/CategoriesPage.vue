<script setup>
import { useRoute, useRouter } from 'vue-router';
// import { OnClickOutside } from '@vueuse/components';
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import CategoryList from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryList.vue';
import CategoryHeaderControls from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue';
// import EditCategory from 'dashboard/playground/HelpCenter/components/EditCategory.vue';

defineProps({
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

// const showEditCategory = ref(false);

// const openEditCategory = () => {
//   showEditCategory.value = true;
// };
// const closeEditCategory = () => {
//   showEditCategory.value = false;
// };

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
</script>

<!-- @edit-category="editCategory" -->
<!-- @new-category="newCategory" -->
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
      <CategoryList :categories="categories" @click="openCategoryArticles" />
    </template>
  </HelpCenterLayout>
</template>
