<script setup>
defineProps({
  buttonText: {
    type: String,
    default: '',
  },
  isActive: {
    type: Boolean,
    default: false,
  },
});
</script>
<template>
  <button
    class="relative inline-flex items-center justify-start w-full p-3 border-0 rounded-none first:rounded-t-xl last:rounded-b-xl h-11 hover:bg-slate-50 dark:hover:bg-slate-700 active:bg-slate-75 dark:active:bg-slate-800"
    @click.stop.prevent="$emit('click')"
    @mouseenter="$emit('mouseenter')"
    @mouseleave="$emit('mouseleave')"
    @focus="$emit('focus')"
  >
    <div class="inline-flex items-center gap-3 overflow-hidden">
      <span
        class="text-sm font-medium truncate text-slate-900 dark:text-slate-50"
      >
        {{ buttonText }}
      </span>
      <fluent-icon
        v-if="isActive"
        icon="checkmark"
        size="18"
        class="flex-shrink-0 text-slate-900 dark:text-slate-50"
      />
    </div>
    <slot name="dropdown" />
  </button>
</template>
