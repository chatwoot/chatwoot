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

<template>
  <Story title="CategoryCard" :layout="{ type: 'grid', width: '400px' }">
    <Variant
      v-for="(category, index) in categories"
      :key="index"
      :title="category.title"
    >
      <CategoryCard
        :title="category.title"
        :description="category.description"
        :articlesCount="category.articlesCount"
      />
    </Variant>
  </Story>
</template>
