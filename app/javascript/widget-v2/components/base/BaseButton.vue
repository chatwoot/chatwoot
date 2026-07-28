<script setup>
import { computed } from 'vue';

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: value => ['primary', 'outline', 'ghost'].includes(value),
  },
  size: {
    type: String,
    default: 'md',
    validator: value => ['sm', 'md', 'lg', 'icon'].includes(value),
  },
  disabled: { type: Boolean, default: false },
});

const variantClasses = computed(
  () =>
    ({
      primary:
        'bg-cw-primary text-cw-primary-foreground hover:bg-cw-primary-strong',
      outline:
        'border border-cw-border bg-cw-solid shadow-sm hover:bg-cw-surface',
      ghost: 'text-cw-text-muted hover:bg-cw-muted hover:text-cw-text',
    })[props.variant]
);

const sizeClasses = computed(
  () =>
    ({
      sm: 'h-8 px-3 gap-1.5',
      md: 'h-9 px-4 gap-2',
      lg: 'h-10 px-6 gap-2',
      icon: 'h-9 w-9 shrink-0',
    })[props.size]
);
</script>

<template>
  <button
    type="button"
    class="inline-flex items-center justify-center whitespace-nowrap text-sm font-520 rounded-token-sm transition-all outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring disabled:opacity-50 disabled:pointer-events-none select-none"
    :class="[variantClasses, sizeClasses]"
    :disabled="disabled"
  >
    <slot />
  </button>
</template>
