<script setup>
import { computed } from 'vue';
import { PercentageChart } from '@chatwoot/viz';

const props = defineProps({
  label: { type: String, required: true },
  used: { type: Number, default: 0 },
  total: { type: Number, default: 0 },
  usageLabel: { type: String, default: '' },
  valueLabel: { type: String, default: '' },
  color: { type: String, default: 'rgb(var(--blue-9))' },
  loading: { type: Boolean, default: false },
});

const chartData = computed(() => ({
  total: Math.max(props.total, 0),
  segments: [
    {
      id: 'used',
      label: props.label,
      value: Math.min(Math.max(props.used, 0), Math.max(props.total, 0)),
      color: props.color,
    },
  ],
}));
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="flex items-center justify-between gap-3 text-xs">
      <span class="text-n-slate-11">
        {{ label }}
        <span v-if="usageLabel" class="text-n-teal-11">
          {{ usageLabel }}
        </span>
      </span>
      <span class="tabular-nums text-n-slate-11">{{ valueLabel }}</span>
    </div>
    <div
      v-if="loading"
      class="w-full h-[0.5625rem] rounded-full bg-n-slate-3 animate-pulse"
    />
    <PercentageChart
      v-else-if="total > 0"
      :data="chartData"
      :aria-label="label"
      :bar-height="9"
      :bar-gap="1"
      :bar-radius="999"
      :show-legend="false"
      :show-tooltip="false"
    />
    <div v-else class="w-full h-[0.5625rem] rounded-full bg-n-alpha-2" />
  </div>
</template>
