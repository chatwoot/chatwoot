<script setup>
import { defineProps } from 'vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => {},
  },
});

const { inbox } = props;
const { inbox_id: inboxId, inbox_name: inboxName } = inbox;
</script>
<template>
  <div
    class="inline-flex items-center rounded-[4px] border border-slate-100 dark:border-slate-600 divide-x divide-slate-100 dark:divide-slate-600 bg-none"
  >
    <div class="flex items-center gap-0.5 py-0.5 px-1.5">
      <fluent-icon
        class="text-slate-600 dark:text-slate-300"
        icon="globe-desktop"
        size="14"
      />
      <span class="font-medium text-slate-600 dark:text-slate-300 text-xs">
        {{ inboxName }}
      </span>
    </div>
    <div class="flex items-center py-0.5 px-1.5">
      <span class="font-medium text-slate-600 dark:text-slate-300 text-xs">
        {{ inboxId }}
      </span>
    </div>
  </div>
</template>
