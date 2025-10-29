<script setup>
import CategoryCard from './CategoryCard.vue';
const categories = [
  {
    id: 1,
    title: 'Getting started',
    description:
      'Learn how to use Chatwoot effectively and make the most of its features to enhance customer support and engagement.',
    articlesCount: 5,
    slug: 'getting-started',
    icon: '🚀',
  },
  {
    id: 2,
    title: 'Marketing',
    description: '',
    articlesCount: 4,
    slug: 'marketing',
    icon: '📈',
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Components/HelpCenter/CategoryCard"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Category Card">
      <div
        v-for="(category, index) in categories"
        :key="index"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <CategoryCard
          :id="category.id"
          :slug="category.slug"
          :title="category.title"
          :description="category.description"
          :articles-count="category.articlesCount"
          :icon="category.icon"
        />
      </div>
    </Variant>
  </Story>
</template>
