<script setup>
import { defineProps } from 'vue';
import inboxCard from './components/InboxCard.vue';

defineProps({
  notifications: {
    type: Array,
    default: () => [],
  },
});
</script>
<template>
  <div
    class="inbox-list-view flex flex-col h-full ltr:border-r border-slate-50 dark:border-slate-800/50"
  >
    <div
      class="flex text-xl pl-5 pr-3 py-2 h-14 items-center font-medium text-slate-900 dark:text-slate-25 border-b border-slate-50 dark:border-slate-800/50"
    >
      Inbox
    </div>
    <div class="flex flex-col w-full h-full overflow-x-hidden overflow-y-auto">
      <inbox-card
        v-for="notificationItem in notifications"
        :key="notificationItem.id"
        :notification-item="notificationItem"
      />
    </div>
  </div>
</template>
<style scoped>
.inbox-list-view {
  width: clamp(360px, 22vw, 460px);
}
</style>
