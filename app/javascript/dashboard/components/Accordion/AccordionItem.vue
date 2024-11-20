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
      class="flex items-center select-none w-full rounded-none bg-slate-50 dark:bg-slate-800 border border-l-0 border-r-0 border-solid m-0 border-slate-100 dark:border-slate-700/50 cursor-grab justify-between py-2 px-4 drag-handle"
      @click.stop="onToggle"
    >
      <div class="flex justify-between mb-0.5">
        <EmojiOrIcon class="inline-block w-5" :icon="icon" :emoji="emoji" />
        <h5
          class="text-slate-800 text-sm dark:text-slate-100 mb-0 py-0 pr-2 pl-0"
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
