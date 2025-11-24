<script setup>
import { computed } from 'vue';

const props = defineProps({
  priorityScore: {
    type: Number,
    default: 0,
  },
  priorityLevel: {
    type: String,
    default: 'normal',
  },
  showScore: {
    type: Boolean,
    default: false,
  },
});

const priorityConfig = computed(() => {
  const configs = {
    critical: {
      label: 'Critical',
      bgClass: 'bg-n-ruby-3',
      textClass: 'text-n-ruby-11',
      iconClass: 'text-n-ruby-10',
      icon: 'i-lucide-alert-circle',
    },
    high_priority: {
      label: 'High',
      bgClass: 'bg-n-orange-3',
      textClass: 'text-n-orange-11',
      iconClass: 'text-n-orange-10',
      icon: 'i-lucide-arrow-up',
    },
    elevated: {
      label: 'Elevated',
      bgClass: 'bg-n-amber-3',
      textClass: 'text-n-amber-11',
      iconClass: 'text-n-amber-10',
      icon: 'i-lucide-trending-up',
    },
    normal: {
      label: 'Normal',
      bgClass: 'bg-n-slate-3',
      textClass: 'text-n-slate-11',
      iconClass: 'text-n-slate-10',
      icon: 'i-lucide-minus',
    },
  };

  return configs[props.priorityLevel] || configs.normal;
});

const tooltipContent = computed(() => {
  if (props.showScore) {
    return `Priority: ${priorityConfig.value.label} (Score: ${props.priorityScore})`;
  }
  return `Priority: ${priorityConfig.value.label}`;
});

const shouldShow = computed(() => {
  // Only show badge for elevated, high, or critical priority
  return ['elevated', 'high_priority', 'critical'].includes(
    props.priorityLevel
  );
});
</script>

<template>
  <span
    v-if="shouldShow"
    v-tooltip="{
      content: tooltipContent,
      delay: { show: 500, hide: 0 },
      hideOnClick: true,
    }"
    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium"
    :class="[priorityConfig.bgClass, priorityConfig.textClass]"
  >
    <span
      class="inline-block size-3"
      :class="[priorityConfig.icon, priorityConfig.iconClass]"
    />
    <span v-if="showScore" class="text-xs font-semibold">
      {{ Math.round(priorityScore) }}
    </span>
  </span>
</template>
