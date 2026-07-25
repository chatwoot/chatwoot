<script setup>
import { computed } from 'vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  /** True when there is a value (or always show floating label). */
  filled: {
    type: Boolean,
    default: false,
  },
  focused: {
    type: Boolean,
    default: false,
  },
  error: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  /** Optional description shown as native title / tooltip on the label. */
  description: {
    type: String,
    default: '',
  },
  /** Allow taller content (multi_list). */
  tall: {
    type: Boolean,
    default: false,
  },
});

const isFloating = computed(() => props.filled || props.focused);

const borderClass = computed(() => {
  if (props.error) return 'border-n-ruby-9';
  if (props.focused) return 'border-n-brand';
  return 'border-n-weak';
});

const labelColorClass = computed(() => {
  if (props.error) return 'text-n-ruby-11';
  if (props.focused) return 'text-n-brand';
  return 'text-n-slate-11';
});
</script>

<template>
  <div
    class="relative w-full rounded-lg border bg-transparent transition-colors group/outlined overflow-visible"
    :class="[
      borderClass,
      tall ? 'min-h-9 py-2' : 'min-h-9',
      disabled ? 'opacity-60 pointer-events-none' : '',
    ]"
  >
    <span
      class="pointer-events-none absolute z-[1] max-w-[calc(100%-1rem)] truncate px-1 transition-all duration-150 ease-out"
      :class="[
        labelColorClass,
        isFloating
          ? 'top-0 ltr:left-2 rtl:right-2 -translate-y-1/2 text-xs leading-none bg-n-solid-1 dark:bg-n-solid-2'
          : 'top-1/2 ltr:left-2.5 rtl:right-2.5 -translate-y-1/2 text-sm font-medium',
      ]"
      :title="description || label"
    >
      {{ label }}
    </span>

    <div
      class="flex items-center gap-1 w-full min-w-0"
      :class="tall ? 'px-2 pt-1' : 'px-2 min-h-9'"
    >
      <div class="flex-1 min-w-0">
        <slot />
      </div>
      <div
        v-if="$slots.trailing"
        class="flex items-center gap-0.5 shrink-0 opacity-0 group-hover/outlined:opacity-100"
      >
        <slot name="trailing" />
      </div>
    </div>
  </div>
</template>
