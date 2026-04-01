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
  <div class="text-sm">
    <button
      class="flex items-center select-none w-full rounded-lg bg-surface-container-high/60 border border-outline-variant/[.12] m-0 cursor-grab justify-between py-2.5 px-4 drag-handle transition-colors hover:bg-surface-container-high"
      :class="{
        'rounded-bl-none rounded-br-none border-b-transparent': isOpen,
      }"
      @click.stop="onToggle"
    >
      <div class="flex justify-between">
        <EmojiOrIcon class="inline-block w-5" :icon="icon" :emoji="emoji" />
        <h5 class="text-on-surface text-sm font-medium mb-0 py-0 pr-2 pl-0">
          {{ title }}
        </h5>
      </div>
      <div class="flex flex-row">
        <slot name="button" />
        <div class="flex justify-end w-3 text-secondary cursor-pointer">
          <fluent-icon v-if="isOpen" size="24" icon="subtract" type="solid" />
          <fluent-icon v-else size="24" icon="add" type="solid" />
        </div>
      </div>
    </button>
    <div
      v-if="isOpen"
      class="border border-outline-variant/[.12] border-t-0 rounded-br-lg rounded-bl-lg bg-surface-container-low/40"
      :class="compact ? 'p-0' : 'px-2 py-4'"
    >
      <slot />
    </div>
  </div>
</template>
