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
      class="relative flex items-center justify-center w-10 h-10 p-0 my-2 rounded-lg text-slate-600 dark:text-slate-100 hover:bg-slate-25 dark:hover:bg-n-solid-3 dark:hover:text-slate-100 hover:text-slate-600"
      :class="{
        'dark:bg-n-solid-3 bg-n-brand/10 text-n-blue-text hover:!bg-n-brand/15 hover:dark:!bg-n-brand/10':
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
