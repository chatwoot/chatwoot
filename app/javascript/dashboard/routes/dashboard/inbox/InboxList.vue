<script>
import { mapGetters } from 'vuex';
import { useAlert, useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import wootConstants from 'dashboard/constants/globals';

import InboxCard from 'dashboard/components-next/Inbox/InboxCard.vue';
import InboxListHeader from './components/InboxListHeader.vue';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';

export default {
  components: {
    InboxCard,
    InboxListHeader,
    IntersectionObserver,
    CmdBarConversationSnooze,
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
      meta: 'notifications/getMeta',
      uiFlags: 'notifications/getUIFlags',
      notification: 'notifications/getFilteredNotifications',
      notificationV4: 'notifications/getFilteredNotificationsV4',
      inboxById: 'inboxes/getInboxById',
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
    notificationsV4() {
      return this.notificationV4(this.inboxFilters);
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
    stateInbox(inboxId) {
      return this.inboxById(inboxId);
    },
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
      useTrack(INBOX_EVENTS.MARK_NOTIFICATION_AS_READ);
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
          this.$store.dispatch('notifications/unReadCount'); // to update the unread count in the store real time
        });
    },
    markNotificationAsUnRead(notification) {
      useTrack(INBOX_EVENTS.MARK_NOTIFICATION_AS_UNREAD);
      this.redirectToInbox();
      const { id } = notification;
      this.$store
        .dispatch('notifications/unread', {
          id,
        })
        .then(() => {
          useAlert(this.$t('INBOX.ALERTS.MARK_AS_UNREAD'));
          this.$store.dispatch('notifications/unReadCount'); // to update the unread count in the store real time
        });
    },
    deleteNotification(notification) {
      useTrack(INBOX_EVENTS.DELETE_NOTIFICATION);
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
    openConversation(notification) {
      const {
        id,
        primaryActorId,
        primaryActorType,
        primaryActor: { inboxId },
        notificationType,
      } = notification;

      if (this.$route.params.notification_id !== id) {
        useTrack(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
          notificationType,
        });

        this.$store
          .dispatch('notifications/read', {
            id,
            primaryActorId,
            primaryActorType,
            unreadCount: this.meta.unreadCount,
          })
          .then(() => {
            this.$store.dispatch('notifications/unReadCount'); // to update the unread count in the store real time
          });

        this.$router.push({
          name: 'inbox_view_conversation',
          params: { inboxId, notification_id: id },
        });
      }
    },
  },
};
</script>

<template>
  <section class="flex w-full h-full bg-n-solid-1">
    <div
      class="flex flex-col h-full w-full lg:min-w-[400px] lg:max-w-[400px] ltr:border-r rtl:border-l border-n-weak"
      :class="!currentNotificationId ? 'flex' : 'hidden xl:flex'"
    >
      <InboxListHeader
        :is-context-menu-open="isInboxContextMenuOpen"
        @filter="onFilterChange"
        @redirect="redirectToInbox"
      />
      <div
        ref="notificationList"
        class="flex flex-col gap-px w-full h-[calc(100%-56px)] pb-3 overflow-x-hidden px-3 overflow-y-auto divide-y divide-n-weak [&>*:hover]:!border-y-transparent [&>*.active]:!border-y-transparent [&>*:hover+*]:!border-t-transparent [&>*.active+*]:!border-t-transparent"
      >
        <InboxCard
          v-for="notificationItem in notificationsV4"
          :key="notificationItem.id"
          :inbox-item="notificationItem"
          :state-inbox="stateInbox(notificationItem.primaryActor?.inboxId)"
          class="rounded-none hover:rounded-xl hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3"
          :class="
            currentNotificationId === notificationItem.id
              ? 'bg-n-alpha-1 dark:bg-n-alpha-3 click-animation rounded-xl active'
              : ''
          "
          @mark-notification-as-read="markNotificationAsRead"
          @mark-notification-as-un-read="markNotificationAsUnRead"
          @delete-notification="deleteNotification"
          @context-menu-open="isInboxContextMenuOpen = true"
          @context-menu-close="isInboxContextMenuOpen = false"
          @click="openConversation(notificationItem)"
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
        <IntersectionObserver
          v-if="!showEndOfList && !uiFlags.isFetching"
          :options="infiniteLoaderOptions"
          @observed="loadMoreNotifications"
        />
      </div>
    </div>
    <router-view />
    <CmdBarConversationSnooze />
  </section>
</template>

<style scoped>
.click-animation {
  animation: click-animation 0.2s ease-in-out;
}

@keyframes click-animation {
  0% {
    transform: scale(1);
  }

  50% {
    transform: scale(0.99);
  }

  100% {
    transform: scale(1);
  }
}
</style>
