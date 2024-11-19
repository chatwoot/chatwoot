<script>
import { mapGetters } from 'vuex';

export default {
  emits: ['openNotificationPanel'],

  computed: {
    ...mapGetters({
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
    isNotificationPanelActive() {
      return this.$route.name === 'notifications_index';
    },
  },
  methods: {
    openNotificationPanel() {
      if (this.$route.name !== 'notifications_index') {
        this.$emit('openNotificationPanel');
      }
    },
  },
};
</script>

<template>
  <div class="mb-4">
    <button
      class="relative flex items-center justify-center w-10 h-10 p-0 my-2 rounded-lg text-slate-600 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500 hover:bg-woot-50':
          isNotificationPanelActive,
      }"
      @click="openNotificationPanel"
    >
      <fluent-icon
        icon="alert"
        :class="{
          'text-woot-500': isNotificationPanelActive,
        }"
      />
      <span
        v-if="unreadCount"
        class="text-black-900 bg-yellow-300 absolute -top-0.5 -right-1 text-xxs min-w-[1rem] rounded-full"
      >
        {{ unreadCount }}
      </span>
    </button>
  </div>
</template>
