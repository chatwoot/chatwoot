<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'resolution',
    validator: value => ['pre-chat', 'resolution'].includes(value),
  },
});

const attributeConfig = {
  'pre-chat': {
    colorClass: 'text-n-blue-11',
    icon: 'i-lucide-message-circle',
    label: 'Pre-chat',
  },
  resolution: {
    colorClass: 'text-n-teal-11',
    icon: 'i-lucide-circle-check-big',
    label: 'Resolution',
  },
};

const config = computed(
  () => attributeConfig[props.type] || attributeConfig.resolution
);
</script>

<template>
  <div
    class="flex gap-1 justify-center items-center px-1.5 py-1 rounded-md shadow outline-1 outline outline-n-container bg-n-solid-2"
  >
    <Icon :icon="config.icon" class="size-4" :class="config.colorClass" />
    <span class="text-xs" :class="config.colorClass">{{ config.label }}</span>
  </div>
</template>
