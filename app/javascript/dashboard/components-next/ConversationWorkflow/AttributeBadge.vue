<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
const props = defineProps({
  type: { type: String, default: 'resolution' },
});
const colorClass = computed(() => {
  const colorMap = {
    'pre-chat': 'blue',
    resolution: 'teal',
  };
  const color = colorMap[props.type] || colorMap.resolution;
  return `text-n-${color}-11`;
});
const iconName = computed(() => {
  const iconMap = {
    'pre-chat': 'i-lucide-message-circle',
    resolution: 'i-lucide-circle-check-big',
  };
  return iconMap[props.type] || iconMap.resolution;
});
const displayLabel = computed(() => {
  const labelMap = {
    'pre-chat': 'Pre-chat',
    resolution: 'Resolution',
  };
  return labelMap[props.type] || labelMap.resolution;
});
</script>

<template>
  <div
    class="flex gap-1 justify-center items-center px-1.5 py-1 rounded-md shadow outline-1 outline outline-n-container bg-n-solid-2"
  >
    <Icon :icon="iconName" class="size-4" :class="colorClass" />
    <span class="text-xs" :class="colorClass">{{ displayLabel }}</span>
  </div>
</template>
