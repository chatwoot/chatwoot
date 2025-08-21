<script setup>
import LibraryResourceCard from './LibraryResourceCard.vue';

defineProps({
  resources: { type: Array, required: true },
  uiFlags: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['viewResource', 'editResource', 'deleteResource']);

const handleViewResource = id => {
  emit('viewResource', id);
};

const handleEditResource = id => {
  emit('editResource', id);
};

const handleDeleteResource = id => {
  emit('deleteResource', id);
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
      :created-at="resource.created_at"
      :resource-type="resource.resource_type"
      :is-deleting="uiFlags.isDeleting"
      @view="handleViewResource"
      @edit="handleEditResource"
      @delete="handleDeleteResource"
    />
  </div>
</template>
