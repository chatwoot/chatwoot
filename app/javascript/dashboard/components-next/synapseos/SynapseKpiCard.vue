<script setup>
import { computed } from 'vue';

const props = defineProps({
  label: { type: String, required: true },
  value: { type: [String, Number], required: true },
  icon: { type: String, default: '' },
  delta: { type: Number, default: null }, // +10.5 ou -3.2 (percentual)
  deltaLabel: { type: String, default: 'vs. período anterior' },
  tone: { type: String, default: 'brand' }, // brand|success|warning|error|neutral
});

const iconToneClass = {
  brand: 'bg-s-brand-soft text-s-brand',
  success: 'bg-s-success-soft text-s-success-text',
  warning: 'bg-s-warning-soft text-s-warning-text',
  error: 'bg-s-error-soft text-s-error-text',
  neutral: 'bg-s-subtle text-s-secondary',
};

const deltaPositive = computed(() => props.delta !== null && props.delta >= 0);
const deltaDisplay = computed(() => {
  if (props.delta === null) return '';
  const sign = props.delta > 0 ? '+' : '';
  return `${sign}${props.delta.toFixed(1)}%`;
});
</script>

<template>
  <div
    class="bg-s-surface border border-s-border rounded-2xl shadow-s-sm p-6 transition-shadow duration-150 ease-out hover:shadow-s-md flex flex-col gap-4"
  >
    <div class="flex items-start justify-between gap-3">
      <span class="text-xs font-medium uppercase tracking-wider text-s-muted">
        {{ label }}
      </span>
      <span
        v-if="icon"
        :class="['inline-flex items-center justify-center size-9 rounded-lg', iconToneClass[tone]]"
      >
        <span :class="['size-4', icon]" />
      </span>
    </div>
    <div class="flex flex-col gap-1">
      <span
        class="font-synapse font-bold tracking-tight text-s-primary leading-none text-[2.75rem]"
      >
        {{ value }}
      </span>
      <div v-if="delta !== null" class="flex items-center gap-1.5 text-xs">
        <span
          :class="[
            'inline-flex items-center gap-0.5 font-medium',
            deltaPositive ? 'text-s-success-text' : 'text-s-error-text',
          ]"
        >
          <span :class="deltaPositive ? 'i-lucide-trending-up size-3.5' : 'i-lucide-trending-down size-3.5'" />
          {{ deltaDisplay }}
        </span>
        <span class="text-s-muted">{{ deltaLabel }}</span>
      </div>
    </div>
  </div>
</template>
