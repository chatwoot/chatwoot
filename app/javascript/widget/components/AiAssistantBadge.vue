<script>
export default {
  name: 'AiAssistantBadge',
  props: {
    isAiTyping: {
      type: Boolean,
      default: false,
    },
  },
};
</script>

<template>
  <div
    v-if="isAiTyping"
    class="flex items-center gap-1.5 px-2 py-1 text-xs rounded-full bg-n-brand-3 text-n-brand-11"
  >
    <span class="relative flex h-2 w-2">
      <span
        class="animate-ping absolute inline-flex h-full w-full rounded-full bg-n-brand opacity-75"
      ></span>
      <span
        class="relative inline-flex rounded-full h-2 w-2 bg-n-brand"
      ></span>
    </span>
    {{ $t('AI_ASSISTANT.TYPING') }}
  </div>
</template>
