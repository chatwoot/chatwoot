<script setup>
import { computed } from 'vue';
const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  consumed: {
    type: Number,
    required: true,
  },
  totalCount: {
    type: Number,
    required: true,
  },
});

const percent = computed(() =>
  Math.round((props.consumed / props.totalCount) * 100)
);

const colorClass = computed(() => {
  if (percent.value < 50) {
    return 'bg-s-success';
  }
  if (percent.value < 80) {
    return 'bg-s-warning';
  }
  return 'bg-s-error';
});
</script>

<template>
  <div
    class="flex gap-5 items-center justify-between text-xs uppercase text-s-muted"
  >
    <div class="font-medium tracking-wider">
      {{ title }}
    </div>
    <div class="tabular-nums">{{ consumed }} / {{ totalCount }}</div>
  </div>
  <div class="rounded-full overflow-hidden h-2 w-full bg-s-subtle mt-2">
    <div class="h-2" :class="colorClass" :style="{ width: `${percent}%` }" />
  </div>
</template>
