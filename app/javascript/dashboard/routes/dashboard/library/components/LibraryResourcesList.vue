<script setup>
import LibraryResourceCard from './LibraryResourceCard.vue';

defineProps({
  resources: { type: Array, required: true },
});

const emit = defineEmits(['viewResource', 'editResource']);

const handleViewResource = id => {
  emit('viewResource', id);
};

const handleEditResource = id => {
  emit('editResource', id);
};
</script>

<template>
  <div class="flex flex-col gap-4 px-6 pt-4 pb-6">
    <LibraryResourceCard
      v-for="resource in resources"
      :id="resource.id"
      :key="resource.id"
      :title="resource.title"
      :description="resource.description"
      :category="resource.category"
      :created-at="resource.createdAt"
      :tags="resource.tags"
      @view="handleViewResource"
      @edit="handleEditResource"
    />
  </div>
</template>
