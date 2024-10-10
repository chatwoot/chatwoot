<script setup>
import HelpCenterLayout from 'dashboard/playground/HelpCenter/components/HelpCenterLayout.vue';
import TabBar from 'dashboard/playground/components/TabBar.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';
import ArticleList from 'dashboard/playground/HelpCenter/components/ArticleList.vue';

const articles = [
  {
    variant: 'Draft article',
    title: "How to get an SSL certificate for your Help Center's custom domain",
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
  {
    variant: 'Archived article',
    title: 'Best practices for organizing your Help Center content',
    status: 'archived',
    updatedAt: '3 days ago',
    author: 'Fernando',
    category: '💰 Finance',
    views: 400,
  },
];

const tabs = [
  { label: 'All articles', count: 24 },
  { label: 'Mine', count: 13 },
  { label: 'Draft', count: 5 },
  { label: 'Archived', count: 11 },
];

// TODO: remove comments
// eslint-disable-next-line no-unused-vars
const handleTabChange = tab => {
  // TODO: Implement tab change logic
};
// eslint-disable-next-line no-unused-vars
const handlePageChange = page => {
  // TODO: Implement page change logic
};
</script>

<template>
  <HelpCenterLayout
    :current-page="1"
    :total-items="100"
    :items-per-page="10"
    @update:current-page="handlePageChange"
  >
    <template #header-actions>
      <div class="flex items-end justify-between">
        <div class="flex flex-col items-start w-full gap-2 lg:flex-row">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="1"
            @tab-changed="handleTabChange"
          />
          <div class="flex items-start justify-between w-full gap-2">
            <div class="flex items-center gap-2">
              <ButtonV4
                label="English"
                size="sm"
                icon-position="right"
                icon="chevron-lucide-down"
                icon-lib="lucide"
                variant="secondary"
              />
              <ButtonV4
                label="All categories"
                size="sm"
                icon-position="right"
                icon="chevron-lucide-down"
                icon-lib="lucide"
                variant="secondary"
              />
            </div>
            <ButtonV4 label="New article" icon="add" size="sm" />
          </div>
        </div>
      </div>
    </template>
    <template #content>
      <ArticleList :articles="articles" />
    </template>
  </HelpCenterLayout>
</template>
