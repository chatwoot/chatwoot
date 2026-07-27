<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  buttons: {
    type: Array,
    default: () => [],
  },
});

const getIconForButton = button => {
  switch (button.type) {
    case 'FLOW':
      return 'i-lucide-square-stack';
    case 'URL':
      return 'i-lucide-link';
    case 'PHONE_NUMBER':
      return 'i-lucide-phone';
    case 'QUICK_REPLY':
    case 'COPY_CODE':
    default:
      return 'i-lucide-message-square';
  }
};

const getButtonTitle = button => {
  if (button.type === 'URL' && button.url) {
    return button.url;
  }
  return button.text || '';
};
</script>

<template>
  <div v-if="buttons.length" class="flex flex-wrap gap-2">
    <div
      v-for="button in buttons"
      :key="`${button.type}-${button.text}`"
      :title="getButtonTitle(button)"
      class="flex items-center gap-1.5 px-2.5 py-1.5 text-xs rounded-lg bg-n-alpha-2 text-n-slate-12 border border-n-slate-4"
    >
      <Icon
        :icon="getIconForButton(button)"
        class="size-3.5 flex-shrink-0 text-n-slate-11"
      />
      <span class="truncate">{{ button.text }}</span>
    </div>
  </div>
</template>
