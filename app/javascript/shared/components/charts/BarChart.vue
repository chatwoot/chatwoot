<script setup>
import { BarChart as VizBarChart } from '@chatwoot/viz';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  ariaLabel: {
    type: String,
    required: true,
  },
  clickable: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['itemClick']);

defineOptions({ inheritAttrs: false });

const handleItemClick = payload => emit('itemClick', payload);
</script>

<template>
  <VizBarChart
    v-bind="$attrs"
    :data="props.data"
    :aria-label="props.ariaLabel"
    :on-item-click="props.clickable ? handleItemClick : undefined"
    class="[--cw-viz-bar-label-color:rgb(var(--slate-11))] [--cw-viz-bar-axis-color:rgb(var(--slate-6))] [--cw-viz-bar-zero-line-color:rgb(var(--slate-8))] [--cw-viz-bar-value-color:rgb(var(--slate-11))] [--cw-viz-bar-tooltip-border-color:rgb(var(--border-strong))] [--cw-viz-bar-tooltip-color:rgb(var(--slate-12))] [--cw-viz-bar-tooltip-background:rgb(var(--solid-2))] [--cw-viz-bar-tooltip-label-color:rgb(var(--slate-11))] [--cw-viz-bar-tooltip-active-color:rgb(var(--slate-12))]"
  />
</template>
