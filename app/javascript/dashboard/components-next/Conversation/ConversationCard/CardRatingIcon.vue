<script setup>
import { computed } from 'vue';

const props = defineProps({
  csatResponse: {
    type: Object,
    default: () => null,
  },
  showLabel: {
    type: Boolean,
    default: false,
  },
});

const config = computed(() => {
  const status = props.csatResponse?.status;
  if (status === 'positive') {
    return { emoji: '👍' };
  }
  if (status === 'negative') {
    return { emoji: '👎' };
  }
  return null;
});
</script>

<template>
  <span
    v-if="config"
    class="flex-shrink-0 inline-flex items-center gap-0.5 text-xs font-medium whitespace-nowrap"
    :class="config.class"
    :title="config.label"
  >
    <span>{{ config.emoji }}</span>
    <span v-if="showLabel">{{ config.label }}</span>
  </span>
</template>
