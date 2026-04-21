<script setup>
defineProps({
  tone: { type: String, default: 'neutral' }, // brand|success|warning|error|neutral
});

const toneStyles = {
  brand: 'bg-s-brand-soft text-s-brand-text',
  success: 'bg-s-success-soft text-s-success-text',
  warning: 'bg-s-warning-soft text-s-warning-text',
  error: 'bg-s-error-soft text-s-error-text',
  neutral: 'bg-s-subtle text-s-secondary',
};
</script>

<template>
  <span
    :class="[
      'inline-flex items-center gap-1 rounded-full text-xs font-medium px-2 py-0.5',
      toneStyles[tone],
    ]"
  >
    <slot />
  </span>
</template>
