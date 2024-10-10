<script setup>
import { ref, computed } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import HelpCenterLayout from 'dashboard/playground/HelpCenter/components/HelpCenterLayout.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
import Breadcrumb from 'dashboard/playground/components/Breadcrumb.vue';
import CategoryList from 'dashboard/playground/HelpCenter/components/CategoryList.vue';
import ArticleList from 'dashboard/playground/HelpCenter/components/ArticleList.vue';
import EditCategory from 'dashboard/playground/HelpCenter/components/EditCategory.vue';

const categories = [
  {
    id: 'getting-started',
    title: '🚀 Getting started',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '2',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
        status: 'draft',
        updatedAt: '2 days ago',
        author: 'Michael',
        category: '⚡️ Marketing',
        views: 3400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
    ],
  },
  {
    id: 'marketing',
    title: 'Marketing',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support.',
    articlesCount: '4',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
        status: 'draft',
        updatedAt: '2 days ago',
        author: 'Michael',
        category: '⚡️ Marketing',
        views: 3400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
      {
        variant: 'Archived article',
        title: 'Best practices for organizing your Help Center content',
        status: 'archived',
        updatedAt: '3 days ago',
        author: 'Fernando',
        category: '💰 Finance',
        views: 400,
      },
      {
        variant: 'Published article',
        title: 'Customizing the appearance of your Help Center',
        status: '',
        updatedAt: '5 days ago',
        author: 'Jane',
        category: '💰 Finance',
        views: 400,
      },
    ],
  },
  {
    id: 'development',
    title: 'Development',
    description: '',
    articlesCount: '5',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
        status: 'draft',
        updatedAt: '2 days ago',
        author: 'Michael',
        category: '⚡️ Marketing',
        views: 3400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
      {
        variant: 'Archived article',
        title: 'Best practices for organizing your Help Center content',
        status: 'archived',
        updatedAt: '3 days ago',
        author: 'Fernando',
        category: '💰 Finance',
        views: 400,
      },
      {
        variant: 'Archived article',
        title: 'Best practices for organizing your Help Center content',
        status: 'archived',
        updatedAt: '3 days ago',
        author: 'Fernando',
        category: '💰 Finance',
        views: 400,
      },
      {
        variant: 'Published article',
        title: 'Customizing the appearance of your Help Center',
        status: '',
        updatedAt: '5 days ago',
        author: 'Jane',
        category: '💰 Finance',
        views: 400,
      },
    ],
  },
  {
    id: 'roadmap',
    title: '🛣️ Roadmap',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '3',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
        status: 'draft',
        updatedAt: '2 days ago',
        author: 'Michael',
        category: '⚡️ Marketing',
        views: 3400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
    ],
  },
  {
    id: 'finance',
    title: '💰 Finance',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: '2',
    articles: [
      {
        variant: 'Draft article',
        title:
          "How to get an SSL certificate for your Help Center's custom domain",
        status: 'draft',
        updatedAt: '2 days ago',
        author: 'Michael',
        category: '⚡️ Marketing',
        views: 3400,
      },
      {
        variant: 'Published article',
        title: 'Setting up your first Help Center portal',
        status: '',
        updatedAt: '1 week ago',
        author: 'John',
        category: '🛠️ Development',
        views: 400,
      },
    ],
  },
];

const selectedCategory = ref(null);

const showEditCategory = ref(false);

const openEditCategory = () => {
  showEditCategory.value = true;
};

const closeEditCategory = () => {
  showEditCategory.value = false;
};

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
  selectedCategory.value = categories.find(category => category.id === id);
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
          <ButtonV4
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
        <ButtonV4
          v-if="!selectedCategory"
          label="New category"
          icon="add"
          size="sm"
        />
        <div v-else class="relative">
          <ButtonV4
            label="Edit category"
            variant="secondary"
            size="sm"
            @click="openEditCategory"
          />
          <OnClickOutside @trigger="closeEditCategory">
            <EditCategory v-if="showEditCategory" @close="closeEditCategory" />
          </OnClickOutside>
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
