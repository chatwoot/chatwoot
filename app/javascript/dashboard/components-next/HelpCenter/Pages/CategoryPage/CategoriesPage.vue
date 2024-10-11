<script setup>
import { ref, computed } from 'vue';
// import { OnClickOutside } from '@vueuse/components';
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import CategoryList from 'dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryList.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';
// import EditCategory from 'dashboard/playground/HelpCenter/components/EditCategory.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
});

const selectedCategory = ref(null);
// const showEditCategory = ref(false);

// const openEditCategory = () => {
//   showEditCategory.value = true;
// };
// const closeEditCategory = () => {
//   showEditCategory.value = false;
// };

const breadcrumbItems = computed(() => {
  const items = [{ label: 'Categories (en-US)', link: '#' }];
  if (selectedCategory.value) {
    items.push({
      label: selectedCategory.value.title,
      count: selectedCategory.value.articles.length,
    });
  }
  return items;
});
const openCategoryArticles = id => {
  selectedCategory.value = props.categories.find(
    category => category.id === id
  );
};
const resetCategory = () => {
  selectedCategory.value = null;
};
const displayedArticles = computed(() => {
  return selectedCategory.value ? selectedCategory.value.articles : [];
});
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <HelpCenterLayout :show-pagination-footer="false">
    <template #header-actions>
      <div class="flex items-center justify-between">
        <div v-if="!selectedCategory" class="flex items-center gap-4">
          <Button
            label="English"
            size="sm"
            icon-position="right"
            icon="chevron-lucide-down"
            icon-lib="lucide"
            variant="secondary"
          />
          <div
            class="w-px h-3.5 rounded my-auto bg-slate-75 dark:bg-slate-800"
          />
          <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
            {{ categories.length }} categories
          </span>
        </div>
        <Breadcrumb v-else :items="breadcrumbItems" @click="resetCategory" />
        <Button
          v-if="!selectedCategory"
          label="New category"
          icon="add"
          size="sm"
        />
        <div v-else class="relative">
          <Button
            label="Edit category"
            variant="secondary"
            size="sm"
            @click="openEditCategory"
          />
          <!-- <OnClickOutside @trigger="closeEditCategory">
            <EditCategory v-if="showEditCategory" @close="closeEditCategory" />
          </OnClickOutside> -->
        </div>
      </div>
    </template>
    <template #content>
      <CategoryList
        v-if="!selectedCategory"
        :categories="categories"
        @click="openCategoryArticles"
      />
      <ArticleList v-else :articles="displayedArticles" />
    </template>
  </HelpCenterLayout>
</template>
