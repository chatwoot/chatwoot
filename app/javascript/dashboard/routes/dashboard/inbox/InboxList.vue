<template>
  <div
    class="flex flex-col h-full w-full ltr:border-r border-slate-50 dark:border-slate-800/50"
    :class="isOnExpandedLayout ? '' : 'min-w-[360px] max-w-[360px]'"
  >
    <inbox-list-header @filter="onFilterChange" />
    <div
      ref="notificationList"
      class="flex flex-col w-full h-[calc(100%-56px)] overflow-x-hidden overflow-y-auto"
    >
      <inbox-card
        v-for="notificationItem in notifications"
        :key="notificationItem.id"
        :notification-item="notificationItem"
        @mark-notification-as-read="markNotificationAsRead"
        @mark-notification-as-unread="markNotificationAsUnRead"
        @delete-notification="deleteNotification"
      />
      <div v-if="uiFlags.isFetching" class="text-center">
        <span class="spinner mt-4 mb-4" />
      </div>
      <p
        v-if="showEmptyState"
        class="text-center text-slate-400 text-sm dark:text-slate-400 p-4 font-medium"
      >
        {{ $t('INBOX.LIST.NO_NOTIFICATIONS') }}
      </p>
      <p
        v-if="showEndOfListMessage"
        class="text-center text-slate-400 dark:text-slate-400 p-4"
      >
        {{ $t('INBOX.LIST.EOF') }}
      </p>
      <intersection-observer
        v-if="!showEndOfList && !uiFlags.isFetching"
        :options="infiniteLoaderOptions"
        @observed="loadMoreNotifications"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import wootConstants from 'dashboard/constants/globals';
import InboxCard from './components/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import alertMixin from 'shared/mixins/alertMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
export default {
  components: {
    InboxCard,
    InboxListHeader,
    IntersectionObserver,
  },
  mixins: [alertMixin, uiSettingsMixin],
  props: {
    conversationId: {
      type: [String, Number],
      default: 0,
    },
    isOnExpandedLayout: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      infiniteLoaderOptions: {
        root: this.$refs.notificationList,
        rootMargin: '100px 0px 100px 0px',
      },
      page: 1,
      status: '',
      type: '',
      sortOrder: wootConstants.INBOX_SORT_BY.NEWEST,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      meta: 'notifications/getMeta',
      uiFlags: 'notifications/getUIFlags',
      notification: 'notifications/getFilteredNotifications',
    }),
    inboxFilters() {
      return {
        page: this.page,
        status: this.status,
        type: this.type,
        sortOrder: this.sortOrder,
      };
    },
    notifications() {
      return this.notification(this.inboxFilters);
    },
    showEndOfList() {
      return this.uiFlags.isAllNotificationsLoaded && !this.uiFlags.isFetching;
    },
    showEmptyState() {
      return !this.uiFlags.isFetching && !this.notifications.length;
    },
    showEndOfListMessage() {
      return this.showEndOfList && this.notifications.length;
    },
  },
  mounted() {
    this.setSavedFilter();
    this.fetchNotifications();
  },
  methods: {
    fetchNotifications() {
      this.page = 1;
      this.$store.dispatch('notifications/clear');
      const filter = this.inboxFilters;

      this.$store.dispatch('notifications/index', filter);
    },
    redirectToInbox() {
      if (!this.conversationId) return;
      if (this.$route.name === 'inbox_view') return;
      this.$router.push({ name: 'inbox_view' });
    },
    loadMoreNotifications() {
      if (this.uiFlags.isAllNotificationsLoaded) return;
      this.$store.dispatch('notifications/index', {
        page: this.page + 1,
        status: this.status,
        type: this.type,
        sortOrder: this.sortOrder,
      });
      this.page += 1;
    },
    markNotificationAsRead(notification) {
      this.$track(INBOX_EVENTS.MARK_NOTIFICATION_AS_READ);
      const {
        id,
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
      } = notification;
      this.$store
        .dispatch('notifications/read', {
          id,
          primaryActorId,
          primaryActorType,
          unreadCount: this.meta.unreadCount,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.MARK_AS_READ'));
        });
    },
    markNotificationAsUnRead(notification) {
      this.$track(INBOX_EVENTS.MARK_NOTIFICATION_AS_UNREAD);
      this.redirectToInbox();
      const { id } = notification;
      this.$store
        .dispatch('notifications/unread', {
          id,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.MARK_AS_UNREAD'));
        });
    },
    deleteNotification(notification) {
      this.$track(INBOX_EVENTS.DELETE_NOTIFICATION);
      this.redirectToInbox();
      this.$store
        .dispatch('notifications/delete', {
          notification,
          unread_count: this.meta.unreadCount,
          count: this.meta.count,
        })
        .then(() => {
          this.showAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
    },
    onFilterChange(option) {
      if (option.type === wootConstants.INBOX_FILTER_TYPE.STATUS) {
        this.status = option.selected ? option.key : '';
      }
      if (option.type === wootConstants.INBOX_FILTER_TYPE.TYPE) {
        this.type = option.selected ? option.key : '';
      }
      if (option.type === wootConstants.INBOX_FILTER_TYPE.SORT_ORDER) {
        this.sortOrder = option.key;
      }
      this.fetchNotifications();
    },
    setSavedFilter() {
      const { inbox_filter_by: filterBy = {} } = this.uiSettings;
      const { status, type, sort_by: sortBy } = filterBy;
      this.status = status;
      this.type = type;
      this.sortOrder = sortBy || wootConstants.INBOX_SORT_BY.NEWEST;
    },
  },
};
</script>
