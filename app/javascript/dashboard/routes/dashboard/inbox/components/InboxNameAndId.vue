<script>
import { getInboxClassByType } from 'dashboard/helper/inbox';

export default {
  props: {
    inbox: {
      type: Object,
      default: () => {},
    },
    conversationId: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    inboxIcon() {
      const { phone_number: phoneNumber, channel_type: type } = this.inbox;
      const classByType = getInboxClassByType(type, phoneNumber);
      return classByType;
    },
  },
};
</script>
<template>
  <div
    class="inline-flex items-center rounded-[4px] border border-slate-100 dark:border-slate-700/50 divide-x divide-slate-100 dark:divide-slate-700/50 bg-none"
  >
    <div v-if="inbox" class="flex items-center gap-0.5 py-0.5 px-1.5">
      <fluent-icon
        class="text-slate-600 dark:text-slate-300"
        :icon="inboxIcon"
        size="14"
      />
      <span class="font-medium text-slate-600 dark:text-slate-200 text-xs">
        {{ inbox.name }}
      </span>
    </div>
    <div class="flex items-center py-0.5 px-1.5">
      <span class="font-medium text-slate-600 dark:text-slate-200 text-xs">
        {{ conversationId }}
      </span>
    </div>
  </div>
</template>
