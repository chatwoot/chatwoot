<script setup>
import HelpCenterLayout from 'dashboard/components-next/HelpCenter/HelpCenterLayout.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ArticleList from 'dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue';

defineProps({
  articles: {
    type: Array,
    required: true,
  },
});

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
              <Button
                label="English"
                size="sm"
                icon-position="right"
                icon="chevron-lucide-down"
                icon-lib="lucide"
                variant="secondary"
              />
              <Button
                label="All categories"
                size="sm"
                icon-position="right"
                icon="chevron-lucide-down"
                icon-lib="lucide"
                variant="secondary"
              />
            </div>
            <Button label="New article" icon="add" size="sm" />
          </div>
        </div>
      </div>
    </template>
    <template #content>
      <ArticleList :articles="articles" />
    </template>
  </HelpCenterLayout>
</template>
