<script setup>
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';

defineProps({
  categories: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['click']);

const handleClick = id => {
  emit('click', id);
};
</script>

<template>
  <ul role="list" class="grid w-full h-full grid-cols-1 gap-4 md:grid-cols-2">
    <CategoryCard
      v-for="category in categories"
      :id="category.id"
      :key="category.title"
      :title="category.title"
      :description="category.description"
      :articles-count="category.articlesCount"
      @click="handleClick(category.id)"
    />
  </ul>
</template>
