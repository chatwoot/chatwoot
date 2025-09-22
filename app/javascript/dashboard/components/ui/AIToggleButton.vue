<script setup>
import { computed } from 'vue';

const props = defineProps({
  aiEnabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggleAi']);

const buttonClasses = computed(() => {
  const baseClasses =
    'inline-flex items-center min-w-0 gap-2 transition-all duration-200 ease-in-out border-0 rounded-lg outline-1 outline disabled:opacity-50 h-8 px-3 text-sm justify-center';

  if (props.aiEnabled) {
    // Active state: main brand color
    return `${baseClasses} bg-n-brand text-white hover:enabled:brightness-110 focus-visible:brightness-110 outline-transparent`;
  }
  // Inactive state: muted/greyed out
  return `${baseClasses} bg-n-slate-3 text-n-slate-11 hover:enabled:bg-n-slate-4 focus-visible:bg-n-slate-4 outline-transparent`;
});

const buttonText = computed(() => {
  return 'AI';
});

const handleClick = () => {
  emit('toggleAi');
};
</script>

<template>
  <button :class="buttonClasses" @click="handleClick">
    <span class="i-lucide-bot flex-shrink-0" />
    <span class="min-w-0 truncate">{{ buttonText }}</span>
  </button>
</template>
