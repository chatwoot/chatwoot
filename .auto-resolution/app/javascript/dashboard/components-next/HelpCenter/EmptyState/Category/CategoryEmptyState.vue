<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';
import categoryContent from 'dashboard/components-next/HelpCenter/EmptyState/Category/categoryEmptyStateContent.js';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="grid grid-cols-2 gap-4 p-px">
        <div class="space-y-4">
          <CategoryCard
            v-for="category in categoryContent"
            :id="category.id"
            :key="category.id"
            :title="category.name"
            :icon="category.icon"
            :description="category.description"
            :articles-count="category.meta.articles_count || 0"
            :slug="category.slug"
          />
        </div>
        <div class="space-y-4">
          <CategoryCard
            v-for="category in categoryContent.reverse()"
            :id="category.id"
            :key="category.id"
            :title="category.name"
            :icon="category.icon"
            :description="category.description"
            :articles-count="category.meta.articles_count || 0"
            :slug="category.slug"
          />
        </div>
      </div>
    </template>
  </EmptyStateLayout>
</template>
