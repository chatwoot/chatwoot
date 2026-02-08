<script>
import Spinner from 'shared/components/Spinner.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import NotificationPanelItem from './NotificationPanelItem.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NotificationPanelItem,
    Spinner,
    EmptyState,
    NextButton,
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
  emits: ['close'],
  computed: {
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

<template>
  <div class="flex-col py-2 px-2.5 overflow-auto h-full flex">
    <NotificationPanelItem
      v-for="notificationItem in notifications"
      v-show="!isLoading"
      :key="notificationItem.id"
      :notification-item="notificationItem"
      @open-notification="onClickNotification"
    />
    <EmptyState
      v-if="showEmptyResult"
      :title="$t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.EMPTY_MESSAGE')"
    />
    <NextButton
      v-if="!isLoading && inLastPage"
      ghost
      class="!w-full mt-3"
      :label="$t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.ALL_NOTIFICATIONS')"
      @click="openNotificationPage"
    />
    <div
      v-if="isLoading"
      class="flex items-center justify-center mx-2 my-12 text-sm font-medium"
    >
      <Spinner />
      <span>{{
        $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.LOADING_UNREAD_MESSAGE')
      }}</span>
    </div>
  </div>
</template>
