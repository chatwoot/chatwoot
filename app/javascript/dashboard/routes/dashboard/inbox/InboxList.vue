<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <div
      class="flex flex-col h-full w-full md:min-w-[360px] md:max-w-[360px] ltr:border-r border-slate-50 dark:border-slate-800/50"
      :class="!currentNotificationId ? 'flex' : 'hidden md:flex'"
    >
      <inbox-list-header
        :is-context-menu-open="isInboxContextMenuOpen"
        @filter="onFilterChange"
        @redirect="redirectToInbox"
      />
      <div
        ref="notificationList"
        class="flex flex-col w-full h-[calc(100%-56px)] overflow-x-hidden overflow-y-auto"
      >
        <inbox-card
          v-for="notificationItem in notifications"
          :key="notificationItem.id"
          :active="currentNotificationId === notificationItem.id"
          :notification-item="notificationItem"
          @mark-notification-as-read="markNotificationAsRead"
          @mark-notification-as-unread="markNotificationAsUnRead"
          @delete-notification="deleteNotification"
          @context-menu-open="isInboxContextMenuOpen = true"
          @context-menu-close="isInboxContextMenuOpen = false"
        />
        <div v-if="uiFlags.isFetching" class="text-center">
          <span class="mt-4 mb-4 spinner" />
        </div>
        <p
          v-if="showEmptyState"
          class="p-4 text-sm font-medium text-center text-slate-400 dark:text-slate-400"
        >
          {{ $t('INBOX.LIST.NO_NOTIFICATIONS') }}
        </p>
        <intersection-observer
          v-if="!showEndOfList && !uiFlags.isFetching"
          :options="infiniteLoaderOptions"
          @observed="loadMoreNotifications"
        />
      </div>
    </div>
    <router-view />
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import wootConstants from 'dashboard/constants/globals';

import InboxCard from './components/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';

export default {
  components: {
    InboxCard,
    InboxListHeader,
    IntersectionObserver,
  },
  setup() {
    const { uiSettings } = useUISettings();

    return {
      uiSettings,
    };
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
      isInboxContextMenuOpen: false,
      notificationIdToSnooze: null,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      meta: 'notifications/getMeta',
      uiFlags: 'notifications/getUIFlags',
      notification: 'notifications/getFilteredNotifications',
    }),
    currentNotificationId() {
      return Number(this.$route.params.notification_id);
    },
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
  },
  watch: {
    inboxFilters(newVal, oldVal) {
      if (newVal !== oldVal) {
        this.$store.dispatch('notifications/updateNotificationFilters', newVal);
      }
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
      if (this.$route.name === 'inbox_view') return;
      this.$router.replace({ name: 'inbox_view' });
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
          useAlert(this.$t('INBOX.ALERTS.MARK_AS_READ'));
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
          useAlert(this.$t('INBOX.ALERTS.MARK_AS_UNREAD'));
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
          useAlert(this.$t('INBOX.ALERTS.DELETE'));
        });
    },
    onFilterChange(option) {
      const { STATUS, TYPE, SORT_ORDER } = wootConstants.INBOX_FILTER_TYPE;
      if (option.type === STATUS) {
        this.status = option.selected ? option.key : '';
      }
      if (option.type === TYPE) {
        this.type = option.selected ? option.key : '';
      }
      if (option.type === SORT_ORDER) {
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
      this.$store.dispatch(
        'notifications/setNotificationFilters',
        this.inboxFilters
      );
    },
  },
};
</script>
