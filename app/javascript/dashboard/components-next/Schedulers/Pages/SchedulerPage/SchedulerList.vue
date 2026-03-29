<script setup>
import SchedulerCard from 'dashboard/components-next/Schedulers/SchedulerCard/SchedulerCard.vue';

defineProps({
  schedulers: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['delete']);
</script>

<template>
  <div class="grid gap-4 md:grid-cols-2">
    <SchedulerCard
      v-for="scheduler in schedulers"
      :key="scheduler.id"
      :scheduler="scheduler"
      @delete="emit('delete', scheduler)"
    />
  </div>
</template>
