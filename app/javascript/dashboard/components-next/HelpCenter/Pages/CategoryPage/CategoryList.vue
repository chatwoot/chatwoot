<script setup>
import { computed, ref, watch } from 'vue';
import Draggable from 'vuedraggable';
import CategoryCard from 'dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue';

const props = defineProps({
  categories: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['click', 'action', 'reorder']);

const localCategories = ref(props.categories);

const dragEnabled = computed(() => {
  return localCategories.value?.length > 1;
});

const handleClick = slug => {
  emit('click', slug);
};

const handleAction = ({ action, value, id }, category) => {
  emit('action', { action, value, id, category });
};

const onDragEnd = () => {
  // Collect and sort existing positions, falling back to index+1 for null/0 values
  const sortedPositions = localCategories.value
    .map((category, index) => category.position || index + 1)
    .sort((a, b) => a - b);

  const reorderedGroup = localCategories.value.reduce(
    (obj, category, index) => {
      obj[category.id] = sortedPositions[index];
      return obj;
    },
    {}
  );

  emit('reorder', reorderedGroup);
};

watch(
  () => props.categories,
  newCategories => {
    localCategories.value = newCategories;
  },
  { deep: true }
);
</script>

<template>
  <Draggable
    v-model="localCategories"
    :disabled="!dragEnabled"
    item-key="id"
    tag="ul"
    role="list"
    class="grid w-full h-full grid-cols-1 gap-4 md:grid-cols-2"
    @end="onDragEnd"
  >
    <template #item="{ element }">
      <li class="list-none">
        <CategoryCard
          :id="element.id"
          :title="element.name"
          :icon="element.icon"
          :description="element.description"
          :articles-count="element.meta?.articles_count || 0"
          :slug="element.slug"
          :class="{ 'cursor-grab': dragEnabled }"
          @click="handleClick(element.slug)"
          @action="handleAction($event, element)"
        />
      </li>
    </template>
  </Draggable>
</template>
