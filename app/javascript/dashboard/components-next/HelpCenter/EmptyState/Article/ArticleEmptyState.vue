<script setup>
// import { ref } from 'vue';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
// import AddLocaleDialog from 'dashboard/playground/HelpCenter/components/AddLocaleDialog.vue';

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

// const addLocaleDialogRef = ref(null);
// const openDialog = () => {
//   addLocaleDialogRef.value.dialogRef.open();
// };
// const handleDialogConfirm = () => {
//   // Add logic to create a new portal
// };
</script>

<!-- TODO: Add i18n -->
<!-- eslint-disable vue/no-bare-strings-in-template -->

<template>
  <EmptyStateLayout
    title="Write an article"
    subtitle="Write a rich article, let's get started!"
  >
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
    <template #actions>
      <Button
        variant="default"
        label="New article"
        icon="add"
        @click="openDialog"
      />
      <!-- <AddLocaleDialog
          ref="addLocaleDialogRef"
          @confirm="handleDialogConfirm"
        /> -->
    </template>
  </EmptyStateLayout>
</template>
