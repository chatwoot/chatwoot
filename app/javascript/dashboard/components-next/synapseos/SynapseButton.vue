<script setup>
import { computed } from 'vue';

const props = defineProps({
  variant: { type: String, default: 'primary' }, // primary|outline|ghost|danger
  size: { type: String, default: 'md' }, // sm|md|lg
  icon: { type: String, default: '' },
  iconTrailing: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
  type: { type: String, default: 'button' },
  block: { type: Boolean, default: false },
});

const variantClasses = {
  primary:
    'bg-s-brand-cta text-s-inverse hover:bg-s-brand-cta-hover active:bg-s-brand-cta-active shadow-s-sm border border-transparent',
  outline:
    'bg-s-surface text-s-secondary hover:bg-s-subtle border border-s-border hover:border-s-border-strong',
  ghost: 'bg-transparent text-s-secondary hover:bg-s-subtle border border-transparent',
  danger:
    'bg-s-error text-s-inverse hover:brightness-110 active:brightness-95 border border-transparent shadow-s-sm',
};

const sizeClasses = {
  sm: 'h-8 px-3 text-xs gap-1.5',
  md: 'h-10 px-4 text-sm gap-2',
  lg: 'h-12 px-5 text-base gap-2',
};

const classes = computed(() => [
  'inline-flex items-center justify-center font-medium rounded-lg transition-all duration-150 ease-out',
  'focus:outline-none focus-visible:ring-2 focus-visible:ring-focus focus-visible:ring-offset-2 focus-visible:ring-offset-s-surface',
  'disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none',
  'active:scale-[0.98]',
  variantClasses[props.variant],
  sizeClasses[props.size],
  props.block ? 'w-full' : '',
]);
</script>

<template>
  <button :type="type" :disabled="disabled || loading" :class="classes">
    <span v-if="loading" class="i-lucide-loader-circle animate-spin size-4 shrink-0" />
    <span v-else-if="icon" :class="['shrink-0 size-4', icon]" />
    <span class="truncate"><slot /></span>
    <span v-if="iconTrailing && !loading" :class="['shrink-0 size-4', iconTrailing]" />
  </button>
</template>
