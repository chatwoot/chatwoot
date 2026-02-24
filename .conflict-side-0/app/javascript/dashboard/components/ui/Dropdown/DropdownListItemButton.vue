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
  icon: {
    type: String,
    default: '',
  },
  iconColor: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <button
    class="relative inline-flex items-center justify-start w-full p-3 border-0 rounded-none first:rounded-t-xl last:rounded-b-xl h-11 hover:enabled:bg-n-alpha-2"
  >
    <div class="inline-flex items-center gap-3 overflow-hidden">
      <fluent-icon
        v-if="icon"
        :icon="icon"
        size="18"
        :style="{ color: iconColor }"
      />
      <span class="text-sm font-medium truncate text-n-slate-12">
        {{ buttonText }}
      </span>
      <fluent-icon
        v-if="isActive"
        icon="checkmark"
        size="18"
        class="flex-shrink-0 text-n-slate-12"
      />
    </div>
    <slot name="dropdown" />
  </button>
</template>
