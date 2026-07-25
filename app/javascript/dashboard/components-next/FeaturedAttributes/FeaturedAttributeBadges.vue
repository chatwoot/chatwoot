<script setup>
import { computed } from 'vue';

const props = defineProps({
  badges: {
    type: Array,
    default: () => [],
  },
  /**
   * Visual tone to tell contact vs conversation featured attrs apart.
   * - contact / emphasized: brand blue
   * - conversation: amber
   * - muted: slate
   */
  variant: {
    type: String,
    default: 'muted',
    validator: v =>
      ['contact', 'conversation', 'emphasized', 'muted'].includes(v),
  },
  /** @deprecated Prefer variant="contact" */
  emphasized: {
    type: Boolean,
    default: false,
  },
});

const resolvedVariant = computed(() => {
  if (props.emphasized && props.variant === 'muted') return 'contact';
  return props.variant;
});

const toneClass = computed(() => {
  const variant = resolvedVariant.value;
  if (variant === 'contact' || variant === 'emphasized') {
    return 'bg-n-brand/10 text-n-brand ring-1 ring-inset ring-n-brand/20';
  }
  if (variant === 'conversation') {
    return 'bg-n-amber-3/80 text-n-amber-11 ring-1 ring-inset ring-n-amber-6/40';
  }
  return 'bg-n-slate-3 text-n-slate-12 dark:bg-n-solid-3';
});
</script>

<template>
  <div v-if="badges.length" class="flex flex-wrap gap-1">
    <span
      v-for="badge in badges"
      :key="badge.key"
      class="inline-flex items-center max-w-full truncate rounded-md px-1.5 py-0.5 text-xxs font-medium"
      :class="toneClass"
      :title="`${badge.label}: ${badge.formatted}`"
    >
      <span class="truncate">{{ badge.label }}: {{ badge.formatted }}</span>
    </span>
  </div>
</template>
