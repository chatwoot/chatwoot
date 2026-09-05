<script setup>
import { CSAT_DISPLAY_TYPES } from 'shared/constants/messages';
import { computed } from 'vue';

const props = defineProps({
  selected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const selectionClass = computed(() => {
  return props.selected
    ? 'bg-n-brand/5 outline-n-brand'
    : 'bg-n-alpha-black2 outline-n-weak';
});

const LIKE_ICON = '👍';
const DISLIKE_ICON = '👎';
</script>

<template>
  <button
    class="flex items-center rounded-lg transition-all duration-300 cursor-pointer outline outline-1 px-4 py-2 gap-3 min-w-56"
    :class="selectionClass"
    @click="emit('update', CSAT_DISPLAY_TYPES.LIKE_DISLIKE)"
  >
    <span class="text-2xl">{{ LIKE_ICON }}</span>
    <span class="text-2xl">{{ DISLIKE_ICON }}</span>
  </button>
</template>
