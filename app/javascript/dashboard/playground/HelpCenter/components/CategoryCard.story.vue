<script setup>
import CategoryCard from './CategoryCard.vue';

const categories = [
  {
    title: 'Getting Started',
    description: 'Essential guides for new users',
    articlesCount: '5',
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="HelpCenter/CategoryCard"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant
      v-for="(category, index) in categories"
      :key="index"
      :title="category.title"
    >
      <CategoryCard
        :title="category.title"
        :description="category.description"
        :articles-count="category.articlesCount"
      />
    </Variant>
  </Story>
</template>
