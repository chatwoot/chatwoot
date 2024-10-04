<template>
  <div class="mb-4">
    <button
      class="text-slate-600 dark:text-slate-100 w-10 h-10 my-2 p-0 flex items-center justify-center rounded-lg hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600 relative"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500 hover:bg-woot-50':
        isNewTicketPageActive,
      }"
      @click="openNewTicketPanel"
    >
      <fluent-icon
        icon="add"
        :class="{
          'text-woot-500': isNewTicketPageActive,
        }"
      />
    </button>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      notificationMetadata: 'notifications/getMeta',
    }),
    unreadCount() {
      if (!this.notificationMetadata.unreadCount) {
        return '';
      }

      return this.notificationMetadata.unreadCount < 100
        ? `${this.notificationMetadata.unreadCount}`
        : '99+';
    },
    isNewTicketPageActive() {
      return this.$route.name === 'conversations_new';
    },
  },
  methods: {
    openNewTicketPanel() {
      if (this.$route.name !== 'conversations_new') {
        this.$emit('open-new-ticket-panel');
      }
    },
  },
};
</script>
