<script setup>
import { computed } from 'vue';

const props = defineProps({
  badges: {
    type: Array,
    default: () => [],
  },
  /**
   * Visual tone + leading icon.
   * - contact / emphasized: brand + person icon
   * - conversation: amber + message icon
   * - muted: slate, no icon preference
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

const isContact = computed(
  () =>
    resolvedVariant.value === 'contact' ||
    resolvedVariant.value === 'emphasized'
);

const isConversation = computed(() => resolvedVariant.value === 'conversation');

const shellClass = computed(() => {
  if (isContact.value) {
    return 'border-n-brand/30 bg-n-brand/5 text-n-brand';
  }
  if (isConversation.value) {
    return 'border-n-amber-6/50 bg-n-amber-3/50 text-n-amber-11';
  }
  return 'border-n-weak bg-n-slate-2 text-n-slate-12';
});

const leadingIcon = computed(() => {
  if (isContact.value) return 'i-lucide-user';
  if (isConversation.value) return 'i-lucide-messages-square';
  return '';
});
</script>

<template>
  <div v-if="badges.length" class="flex flex-wrap gap-1.5">
    <span
      v-for="badge in badges"
      :key="badge.key"
      class="inline-flex items-center max-w-full gap-1 truncate rounded-lg border px-2 py-1 text-xs font-medium"
      :class="shellClass"
      :title="`${badge.label}: ${badge.formatted}`"
    >
      <span
        v-if="leadingIcon"
        :class="leadingIcon"
        class="size-3.5 shrink-0 opacity-80"
      />
      <span class="truncate">{{ badge.label }}: {{ badge.formatted }}</span>
    </span>
  </div>
</template>
