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
        'bg-cw-primary text-cw-primary-foreground hover:bg-cw-primary-strong border border-transparent',
      outline:
        'bg-cw-background text-cw-text border border-cw-border hover:bg-cw-muted',
      ghost:
        'bg-transparent text-cw-text-muted hover:bg-cw-muted border border-transparent',
    })[props.variant]
);

const sizeClasses = computed(
  () =>
    ({
      sm: 'h-8 px-3 text-xs gap-1.5',
      md: 'h-10 px-4 text-sm gap-2',
      lg: 'h-11 px-5 text-sm gap-2',
      icon: 'h-9 w-9 shrink-0',
    })[props.size]
);
</script>

<template>
  <button
    type="button"
    class="inline-flex items-center justify-center font-medium rounded-token-sm transition-colors duration-150 outline-none focus-visible:ring-2 focus-visible:ring-cw-primary focus-visible:ring-offset-2 focus-visible:ring-offset-cw-background disabled:opacity-50 disabled:pointer-events-none select-none"
    :class="[variantClasses, sizeClasses]"
    :disabled="disabled"
  >
    <slot />
  </button>
</template>
