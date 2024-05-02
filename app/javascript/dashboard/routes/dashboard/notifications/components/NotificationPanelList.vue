<template>
  <div class="flex-col py-2 px-2.5 overflow-auto h-full flex">
    <notification-panel-item
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      :notification-item="notificationItem"
      @open-notification="onClickNotification"
    />
    <empty-state
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.EMPTY_MESSAGE')"
    />
    <woot-button
      v-if="!isLoading && inLastPage"
      size="expanded"
      variant="clear"
      color-scheme="primary"
      class-names="mt-3"
      @click="openNotificationPage"
    >
      {{ $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.ALL_NOTIFICATIONS') }}
    </woot-button>
    <div
      v-if="isLoading"
      class="items-center justify-center my-12 mx-2 text-sm font-medium flex"
    >
      <spinner />
      <span>{{
        $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.LOADING_UNREAD_MESSAGE')
      }}</span>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NotificationPanelItem from './NotificationPanelItem.vue';

export default {
  components: {
    NotificationPanelItem,
    Spinner,
    EmptyState,
  },
  props: {
    notifications: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: true,
    },
    onClickNotification: {
      type: Function,
      default: () => {},
    },
    inLastPage: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      notificationMetadata: 'notifications/getMeta',
    }),
    showEmptyResult() {
      return !this.isLoading && this.notifications.length === 0;
    },
  },
  methods: {
    openNotificationPage() {
      if (this.$route.name !== 'notifications_index') {
        this.$router.push({
          name: 'notifications_index',
        });
      }
      this.$emit('close');
    },
  },
};
</script>
