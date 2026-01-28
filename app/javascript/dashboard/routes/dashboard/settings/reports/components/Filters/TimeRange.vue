<script setup>
import { ref, watch } from 'vue';

const emit = defineEmits(['timeRangeChanged']);
const timeFrom = ref('00:00');
const timeTo = ref('23:59');

watch(
  [timeFrom, timeTo],
  () => {
    emit('timeRangeChanged', {
      since: timeFrom.value,
      until: timeTo.value,
    });
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex items-center gap-1">
    <input
      v-model="timeFrom"
      type="time"
      class="px-2 py-1 rounded text-sm time-input no-margin rounded-lg bg-n-alpha-2 hover:bg-n-alpha-1 active:bg-n-alpha-1"
    />

    <input
      v-model="timeTo"
      type="time"
      class="px-2 py-1 rounded text-sm time-input no-margin rounded-lg bg-n-alpha-2 hover:bg-n-alpha-1 active:bg-n-alpha-1"
    />
  </div>
</template>
