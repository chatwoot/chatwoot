<script setup>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';
import { defineEmits } from 'vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
  emoji: {
    type: String,
    default: '',
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['toggle']);

const onToggle = () => {
  emit('toggle');
};
</script>

<template>
  <div class="-mt-px text-sm">
    <button
      class="flex items-center justify-between w-full px-4 py-2 m-0 border border-l-0 border-r-0 border-solid rounded-none select-none bg-n-slate-3 dark:bg-n-solid-2 border-n-weak dark:border-n-weak cursor-grab drag-handle"
      @click.stop="onToggle"
    >
      <div class="flex justify-between mb-0.5">
        <EmojiOrIcon class="inline-block w-5" :icon="icon" :emoji="emoji" />
        <h5
          class="py-0 pl-0 pr-2 mb-0 text-sm text-slate-800 dark:text-slate-100"
        >
          {{ title }}
        </h5>
      </div>
      <div class="flex flex-row">
        <slot name="button" />
        <div class="flex justify-end w-3 text-woot-500">
          <fluent-icon v-if="isOpen" size="24" icon="subtract" type="solid" />
          <fluent-icon v-else size="24" icon="add" type="solid" />
        </div>
      </div>
    </button>
    <div
      v-if="isOpen"
      class="bg-white dark:bg-slate-900"
      :class="compact ? 'p-0' : 'p-4'"
    >
      <slot />
    </div>
  </div>
</template>
