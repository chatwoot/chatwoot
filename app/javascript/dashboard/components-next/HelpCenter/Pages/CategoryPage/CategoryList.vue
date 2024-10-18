<script setup>
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';

defineProps({
  categories: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['click', 'action']);

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action, value, id }, category) => {
  emit('action', { action, value, id, category });
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
      @action="handleAction($event, category)"
    />
  </ul>
</template>
