<script setup>
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';

defineProps({
  categories: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['click']);

const handleClick = slug => {
  emit('click', slug);
};
</script>

<template>
  <ul role="list" class="grid w-full h-full grid-cols-1 gap-4 md:grid-cols-2">
    <CategoryCard
      v-for="category in categories"
      :id="category.id"
      :key="category.id"
      :title="category.name"
      :icon="category.icon"
      :description="category.description"
      :articles-count="category.meta.articles_count || 0"
      :slug="category.slug"
      @click="handleClick(category.slug)"
    />
  </ul>
</template>
