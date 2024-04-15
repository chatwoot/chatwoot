<script setup>
import { calendarWeeks } from '../helpers/DatePickerHelper';
</script>

<template>
  <div class="grid max-w-md grid-cols-7 gap-2 mx-auto">
    <div
      v-for="day in calendarWeeks"
      :key="day.id"
      class="flex items-center justify-center font-medium text-sm w-9 h-7 py-1.5 px-2"
    >
      {{ day.label }}
    </div>
  </div>
</template>
