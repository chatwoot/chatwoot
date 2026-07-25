<script setup>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';

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
      class="flex items-center select-none w-full rounded-lg bg-n-slate-2 outline outline-1 outline-n-weak m-0 cursor-grab justify-between drag-handle"
      :class="[
        compact ? 'py-1.5 px-3' : 'py-2 px-4',
        { 'rounded-bl-none rounded-br-none': isOpen },
      ]"
      @click.stop="onToggle"
    >
      <div class="flex justify-between items-center">
        <EmojiOrIcon
          class="inline-block w-5"
          :class="compact ? 'w-4' : 'w-5'"
          :icon="icon"
          :emoji="emoji"
        />
        <h5
          class="text-n-slate-12 mb-0 py-0 pr-2 pl-0"
          :class="compact ? 'text-sm font-semibold tracking-wide' : 'text-sm'"
        >
          {{ title }}
        </h5>
      </div>
      <div class="flex flex-row">
        <slot name="button" />
        <div class="flex justify-end w-3 text-n-blue-11 cursor-pointer">
          <fluent-icon
            v-if="isOpen"
            :size="compact ? 20 : 24"
            icon="subtract"
            type="solid"
          />
          <fluent-icon
            v-else
            :size="compact ? 20 : 24"
            icon="add"
            type="solid"
          />
        </div>
      </div>
    </button>
    <div
      v-if="isOpen"
      class="outline outline-1 -mt-[-1px] border-t-0 rounded-br-lg rounded-bl-lg"
      :class="compact ? 'p-1.5 outline-n-strong' : 'px-2 py-4 outline-n-weak'"
    >
      <slot />
    </div>
  </div>
</template>
