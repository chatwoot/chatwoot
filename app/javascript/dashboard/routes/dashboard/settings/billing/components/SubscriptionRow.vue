<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  value: {
    type: [String, Number],
    default: '',
  },
  actionText: {
    type: String,
    default: '',
  },
  actionDisabled: {
    type: Boolean,
    default: false,
  },
  showAction: {
    type: Boolean,
    default: true,
  },
});

defineEmits(['action']);
</script>

<template>
  <div
    class="flex items-center justify-between py-4 border-b border-n-weak last:border-b-0"
  >
    <div class="flex flex-col gap-1">
      <span
        class="text-xs font-medium tracking-wider uppercase text-n-slate-10"
      >
        {{ label }}
      </span>
      <slot name="value">
        <span class="text-base font-medium text-n-slate-12">
          {{ value }}
        </span>
      </slot>
    </div>
    <slot name="action">
      <button
        v-if="actionText && showAction"
        type="button"
        class="text-sm font-medium transition-colors text-n-slate-11 hover:text-n-slate-12 disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="actionDisabled"
        @click="$emit('action')"
      >
        {{ actionText }}
      </button>
    </slot>
  </div>
</template>
