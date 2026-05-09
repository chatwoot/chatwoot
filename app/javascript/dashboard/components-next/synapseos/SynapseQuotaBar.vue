<script setup>
import { computed } from 'vue';

const props = defineProps({
  used: { type: Number, default: 0 },
  quota: { type: Number, required: true },
});

const ratio = computed(() => (props.quota > 0 ? props.used / props.quota : 0));
const percent = computed(() => Math.round(ratio.value * 100));
const overage = computed(() => Math.max(props.used - props.quota, 0));

// 0-69% verde, 70-89% âmbar, 90-99% laranja escuro, ≥100% vermelho.
const tone = computed(() => {
  if (ratio.value >= 1) return 'error';
  if (ratio.value >= 0.9) return 'warning';
  if (ratio.value >= 0.7) return 'info';
  return 'success';
});

const trackTone = {
  success: 'bg-s-success',
  info: 'bg-s-accent',
  warning: 'bg-s-warning',
  error: 'bg-s-error',
};

// Largura visual capada em 100% mesmo se passar da quota — pra não estourar
// o container; a tag de excedente cuida da informação numérica.
const fillWidth = computed(() => `${Math.min(percent.value, 100)}%`);
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <div
      class="h-2 w-full rounded-full bg-s-subtle overflow-hidden"
      role="progressbar"
      :aria-valuenow="percent"
      aria-valuemin="0"
      aria-valuemax="100"
    >
      <div
        :class="['h-full rounded-full transition-all duration-300', trackTone[tone]]"
        :style="{ width: fillWidth }"
      />
    </div>
    <slot :percent="percent" :tone="tone" :overage="overage" />
  </div>
</template>
