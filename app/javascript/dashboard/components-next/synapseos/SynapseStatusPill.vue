<script setup>
defineProps({
  tone: { type: String, default: 'neutral' }, // success|warning|error|info|brand|neutral
  size: { type: String, default: 'md' }, // sm|md
});

const toneStyles = {
  success: { bg: 'bg-s-success-soft', text: 'text-s-success-text', dot: 'bg-s-success' },
  warning: { bg: 'bg-s-warning-soft', text: 'text-s-warning-text', dot: 'bg-s-warning' },
  error: { bg: 'bg-s-error-soft', text: 'text-s-error-text', dot: 'bg-s-error' },
  info: { bg: 'bg-s-info-soft', text: 'text-s-brand-text', dot: 'bg-s-info' },
  brand: { bg: 'bg-s-brand-soft', text: 'text-s-brand-text', dot: 'bg-s-brand' },
  neutral: { bg: 'bg-s-subtle', text: 'text-s-secondary', dot: 'bg-s-muted' },
};

const sizeClass = {
  sm: 'text-[11px] h-5 px-1.5 gap-1',
  md: 'text-xs h-6 px-2 gap-1.5',
};
</script>

<template>
  <span
    :class="[
      'inline-flex items-center rounded-full font-medium',
      toneStyles[tone].bg,
      toneStyles[tone].text,
      sizeClass[size],
    ]"
  >
    <span :class="['size-1.5 rounded-full shrink-0', toneStyles[tone].dot]" />
    <slot />
  </span>
</template>
