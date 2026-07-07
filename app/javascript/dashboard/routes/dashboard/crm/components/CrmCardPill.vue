<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  // Lucide icon name (e.g. 'i-lucide-calendar-clock'). Optional.
  icon: {
    type: String,
    default: '',
  },
  // Visual tone. 'default' = slate; 'ruby'/'amber'/'blue'/'teal' for signals.
  tone: {
    type: String,
    default: 'default',
    validator: value =>
      ['default', 'ruby', 'amber', 'blue', 'teal'].includes(value),
  },
  // Optional tooltip text (e.g. absolute timestamp behind a relative label).
  title: {
    type: String,
    default: '',
  },
});

const toneClasses = {
  default: 'bg-n-alpha-2 text-n-slate-11',
  ruby: 'bg-n-ruby-3 text-n-ruby-11',
  amber: 'bg-n-amber-3 text-n-amber-11',
  blue: 'bg-n-blue-3 text-n-blue-11',
  teal: 'bg-n-teal-3 text-n-teal-11',
};
</script>

<template>
  <span
    v-tooltip.top="
      title ? { content: title, delay: { show: 500, hide: 0 } } : null
    "
    class="inline-flex min-w-0 max-w-full items-center gap-1 rounded-md px-1.5 py-0.5 text-[11px] font-medium leading-4"
    :class="toneClasses[tone] || toneClasses.default"
  >
    <slot name="lead">
      <Icon v-if="icon" :icon="icon" class="size-3 shrink-0" />
    </slot>
    <span class="truncate"><slot /></span>
    <!-- Trailing affix (e.g. "+N" badge) — outside the truncating span so it
         is never clipped by a long main label. -->
    <slot name="trail" />
  </span>
</template>
