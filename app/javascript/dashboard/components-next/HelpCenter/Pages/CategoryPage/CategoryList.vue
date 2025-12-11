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

const handleAction = ({ action, id }, category) => {
  emit('action', { action, id, category });
};
</script>

<template>
  <ul role="list" class="flex w-full h-full flex-col gap-4">
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
