<script setup>
import { ref } from 'vue';
import EmptyStateLayout from 'dashboard/playground/components/EmptyStateLayout.vue';
import ArticleCard from 'dashboard/playground/HelpCenter/ArticleCard.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
// import AddLocaleDialog from 'dashboard/playground/HelpCenter/AddLocaleDialog.vue';

const articles = [
  {
    title: "How to get an SSL certificate for your Help Center's custom domain",
    status: 'draft',
    updatedAt: '2 days ago',
    author: 'Michael',
    category: '⚡️ Marketing',
    views: 3400,
  },
  {
    title: 'Setting up your first Help Center portal',
    status: '',
    updatedAt: '1 week ago',
    author: 'John',
    category: '🛠️ Development',
    views: 400,
  },
  {
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: '3 days ago',
    author: 'Fernando',
    category: '💰 Finance',
    views: 400,
  },
  {
    title: 'Customizing the appearance of your Help Center',
    status: '',
    updatedAt: '5 days ago',
    author: 'Jane',
    category: '💰 Finance',
    views: 400,
  },
];

const addLocaleDialogRef = ref(null);

const openDialog = () => {
  addLocaleDialogRef.value.dialogRef.open();
};

const handleDialogConfirm = () => {
  // Add logic to create a new portal
};
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <EmptyStateLayout>
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4">
        <ArticleCard
          v-for="(article, index) in articles"
          :key="`article-${index}`"
          :title="article.title"
          :status="article.status"
          :updated-at="article.updatedAt"
          :author="article.author"
          :category="article.category"
          :views="article.views"
        />
      </div>
    </template>
    <template #empty-state>
      <div class="flex flex-col items-center justify-center gap-6">
        <div class="flex flex-col items-center justify-center gap-2">
          <h2
            class="text-3xl font-medium text-center text-slate-900 dark:text-white"
          >
            Write an article
          </h2>
          <p
            class="max-w-lg text-base text-center text-slate-600 dark:text-slate-300"
          >
            Write a rich article, let’s get started!
          </p>
        </div>
        <ButtonV4
          variant="default"
          label="New article"
          icon="add"
          @click="openDialog"
        />
        <!-- <AddLocaleDialog
          ref="addLocaleDialogRef"
          @confirm="handleDialogConfirm"
        /> -->
      </div>
    </template>
  </EmptyStateLayout>
</template>
