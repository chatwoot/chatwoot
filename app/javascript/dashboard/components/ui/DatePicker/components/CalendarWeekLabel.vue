<script setup>
import { computed } from 'vue';
import { calendarWeeks } from '../helpers/DatePickerHelper';

const weekLabels = computed(() => calendarWeeks());
</script>

<template>
  <div class="max-w-md mx-auto grid grid-cols-7 gap-2">
    <div
      v-for="day in weekLabels"
      :key="day.id"
      class="flex items-center justify-center font-medium text-sm w-9 h-7 py-1.5 px-2"
    >
      {{ day.label }}
    </div>
  </div>
</template>
