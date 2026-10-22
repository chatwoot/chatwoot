<script setup>
import { computed } from 'vue';

const props = defineProps({
  done: { type: Number, required: true },
  total: { type: Number, required: true },
});

const percent = computed(() => Math.round((props.done / props.total) * 100));
</script>

<template>
  <div
    role="progressbar"
    :aria-valuenow="done"
    :aria-valuemax="total"
    class="h-1.5 w-full overflow-hidden rounded-full bg-n-alpha-2"
  >
    <div
      class="h-full rounded-full bg-n-brand transition-all duration-500"
      :style="{ width: `${percent}%` }"
    />
  </div>
</template>
