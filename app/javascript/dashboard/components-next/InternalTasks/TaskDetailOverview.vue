<script setup>
import { computed } from 'vue';
import TaskProcessTracker from './TaskProcessTracker.vue';

const props = defineProps({
  task: { type: Object, required: true },
  compact: { type: Boolean, default: false },
});

const isTerminal = computed(() =>
  ['completed', 'cancelled'].includes(props.task.status)
);

const metadataEntries = computed(() =>
  Object.entries(props.task.metadata || {}).filter(([, value]) => value)
);
</script>

<template>
  <div
    v-if="!isTerminal || metadataEntries.length"
    class="flex flex-col gap-3"
    :class="compact ? 'px-4 py-3' : 'px-4 py-4'"
  >
    <TaskProcessTracker v-if="!isTerminal" :task="task" />

    <div v-if="metadataEntries.length" class="flex flex-wrap gap-1.5">
      <span
        v-for="[key, value] in metadataEntries"
        :key="key"
        class="inline-flex items-center gap-1 rounded-md bg-n-alpha-2 px-2 py-1 text-xs text-n-slate-11"
      >
        <span class="font-medium text-n-slate-12">{{ key }}:</span>
        {{ value }}
      </span>
    </div>
  </div>
</template>
