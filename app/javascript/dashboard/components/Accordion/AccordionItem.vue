<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
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
  <div class="text-sm p-4 grid gap-2">
    <button
      class="flex items-center select-none w-full m-0 cursor-grab justify-between drag-handle p-0"
      @click.stop="onToggle"
    >
      <h5 class="text-n-slate-12 text-sm font-medium mb-0 py-0 pr-2 pl-0">
        {{ title }}
      </h5>
      <div
        class="flex justify-end w-3 text-n-blue-text flex-shrink-0 cursor-pointer size-4"
      >
        <Icon
          v-if="isOpen"
          icon="i-lucide-chevron-up"
          class="size-4 text-n-slate-11"
        />
        <Icon
          v-else
          icon="i-lucide-chevron-down"
          class="size-4 text-n-slate-11"
        />
      </div>
    </button>
    <div v-if="isOpen">
      <slot />
    </div>
  </div>
</template>
