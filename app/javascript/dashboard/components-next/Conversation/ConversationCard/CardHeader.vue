<script setup>
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';

defineProps({
  contactName: { type: String, required: true },
  timestamp: { type: Number, required: true },
  createdAt: { type: Number, required: true },
});
</script>

<template>
  <div class="grid grid-cols-[1fr_auto] items-center gap-2 h-5">
    <h4 class="text-sm my-0 capitalize truncate text-n-slate-12 font-medium">
      {{ contactName }}
    </h4>

    <TimeAgo
      :last-activity-timestamp="timestamp"
      :created-at-timestamp="createdAt"
      class="font-440 !text-xs shrink-0"
    />
  </div>
</template>
