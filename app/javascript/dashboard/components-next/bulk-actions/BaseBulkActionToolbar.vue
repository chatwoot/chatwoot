<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  selectedCount: {
    type: Number,
    default: 0,
  },
  selectionLabel: {
    type: String,
    default: '',
  },
  clearLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['clearSelection']);

const hasSelection = computed(() => props.selectedCount > 0);

const handleClearSelection = () => {
  emit('clearSelection');
};
</script>

<template>
  <transition
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 translate-y-4"
    enter-to-class="opacity-100 translate-y-0"
    leave-active-class="transition-all duration-200 ease-in"
    leave-from-class="opacity-100 translate-y-0"
    leave-to-class="opacity-0 translate-y-2"
  >
    <div
      v-if="hasSelection"
      class="fixed inset-x-0 bottom-6 z-40 flex justify-center pointer-events-none"
    >
      <div
        class="pointer-events-auto flex items-center gap-4 px-5 py-3 rounded-full shadow-lg bg-n-solid-1 border border-n-weak dark:border-n-slate-6"
      >
        <div class="flex items-center gap-2 text-sm text-n-slate-12">
          <span class="font-medium tabular-nums">
            {{ selectionLabel }}
          </span>
        </div>
        <div class="flex items-center gap-3">
          <Button
            v-if="clearLabel"
            size="sm"
            variant="ghost"
            color="slate"
            :label="clearLabel"
            class="!px-3"
            @click="handleClearSelection"
          />
          <slot />
        </div>
      </div>
    </div>
  </transition>
</template>
