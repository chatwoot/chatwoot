<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: { type: String, required: true },
  color: { type: String, default: '' },
  index: { type: Number, default: 0 },
});

const emit = defineEmits(['accept', 'reject']);

const STAGGER_CLASSES = [
  '[animation-delay:0ms]',
  '[animation-delay:70ms]',
  '[animation-delay:140ms]',
];
</script>

<template>
  <div
    class="relative inline-flex items-center h-6 mb-1 overflow-hidden text-xs font-medium border rounded pe-1 me-1 border-n-iris-6 bg-n-iris-2 text-n-slate-12 transition-all duration-150 hover:bg-n-iris-3 hover:border-n-iris-7 hover:-translate-y-px active:translate-y-0 active:scale-95 animate-pop-in before:absolute before:inset-0 before:bg-gradient-to-r before:from-transparent before:via-white/50 dark:before:via-white/5 before:to-transparent before:animate-shimmer before:pointer-events-none"
    :class="STAGGER_CLASSES[index] || STAGGER_CLASSES.at(-1)"
  >
    <button
      type="button"
      class="flex items-center h-full min-w-0 gap-1 px-1 py-0 text-xs rounded-sm outline-none focus-visible:outline-2 focus-visible:outline-n-brand focus-visible:-outline-offset-2"
      :title="$t('CONVERSATION.SUGGESTIONS.ACCEPT')"
      @click="emit('accept')"
    >
      <Icon
        icon="i-ph-sparkle-fill"
        class="flex-shrink-0 size-3 text-n-iris-9"
      />
      <span
        v-if="color"
        class="inline-block flex-shrink-0 w-3 h-3 rounded-sm shadow-sm"
        :style="{ background: color }"
      />
      <span class="overflow-hidden whitespace-nowrap text-ellipsis">
        {{ title }}
      </span>
    </button>
    <button
      type="button"
      class="flex items-center justify-center p-0 rounded-sm outline-none text-n-slate-11 transition-colors hover:bg-n-iris-4 hover:text-n-slate-12 focus-visible:outline-2 focus-visible:outline-n-brand focus-visible:outline-offset-0"
      :title="$t('CONVERSATION.SUGGESTIONS.REJECT')"
      @click="emit('reject')"
    >
      <Icon icon="i-lucide-x" class="size-3" />
    </button>
  </div>
</template>
