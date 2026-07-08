<script setup>
import { computed } from 'vue';
import { priorityTheme } from '../utils/prospectingPriority';

const props = defineProps({
  priority: {
    type: Number,
    default: null,
  },
  size: {
    type: Number,
    default: 56,
  },
});

const normalizedPriority = computed(() => {
  if (props.priority === null || props.priority === undefined) return null;

  return Math.max(0, Math.min(100, Math.round(Number(props.priority))));
});

const theme = computed(() =>
  normalizedPriority.value === null
    ? null
    : priorityTheme(normalizedPriority.value)
);
const stroke = computed(() => (props.size >= 80 ? 8 : 6));
const radius = computed(() => (props.size - stroke.value) / 2);
const circumference = computed(() => 2 * Math.PI * radius.value);
const dashOffset = computed(() => {
  if (normalizedPriority.value === null) return circumference.value;

  return circumference.value * (1 - normalizedPriority.value / 100);
});
</script>

<template>
  <div
    v-if="normalizedPriority === null"
    class="flex shrink-0 items-center justify-center rounded-full bg-n-solid-2 text-xs text-n-slate-10"
    :style="{ width: `${size}px`, height: `${size}px` }"
  >
    -
  </div>
  <svg
    v-else
    :width="size"
    :height="size"
    :viewBox="`0 0 ${size} ${size}`"
    class="shrink-0"
    role="img"
    :aria-label="`Prioridade ${normalizedPriority} de 100`"
  >
    <circle
      :cx="size / 2"
      :cy="size / 2"
      :r="radius"
      fill="none"
      :stroke="theme.ringBg"
      :stroke-width="stroke"
    />
    <circle
      :cx="size / 2"
      :cy="size / 2"
      :r="radius"
      fill="none"
      :stroke="theme.ring"
      :stroke-width="stroke"
      :stroke-dasharray="circumference"
      :stroke-dashoffset="dashOffset"
      stroke-linecap="round"
      :transform="`rotate(-90 ${size / 2} ${size / 2})`"
      class="transition-all duration-500"
    />
    <text
      :x="size / 2"
      :y="size / 2"
      text-anchor="middle"
      dominant-baseline="central"
      :font-size="size * 0.34"
      font-weight="700"
      :fill="theme.ringText"
    >
      {{ normalizedPriority }}
    </text>
  </svg>
</template>
