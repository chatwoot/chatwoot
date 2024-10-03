<script>
import { mapGetters } from 'vuex';
import NotificationPanelList from './NotificationPanelList.vue';
import { useTrack } from 'dashboard/composables';
import { ACCOUNT_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    NotificationPanelList,
  },
  emits: ['close'],
  data() {
    return {
      pageSize: 15,
    };
  },
  computed: {
    ...mapGetters({
      meta: 'notifications/getMeta',
      records: 'notifications/getNotifications',
      uiFlags: 'notifications/getUIFlags',
    }),
    totalUnreadNotifications() {
      return this.meta.unreadCount;
    },
    noUnreadNotificationAvailable() {
      return this.meta.unreadCount === 0;
    },
    getUnreadNotifications() {
      return this.records.filter(notification => notification.read_at === null);
    },
    currentPage() {
      return Number(this.meta.currentPage);
    },
    lastPage() {
      if (this.totalUnreadNotifications > 15) {
        return Math.ceil(this.totalUnreadNotifications / this.pageSize);
      }
      return 1;
    },
    inFirstPage() {
      const page = Number(this.meta.currentPage);
      return page === 1;
    },
    inLastPage() {
      return this.currentPage === this.lastPage;
    },
  },
  mounted() {
    this.$store.dispatch('notifications/get', { page: 1 });
  },
  methods: {
    onPageChange(page) {
      this.$store.dispatch('notifications/get', { page });
    },
    openConversation(notification) {
      const {
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { id: conversationId },
        notification_type: notificationType,
      } = notification;

      useTrack(ACCOUNT_EVENTS.OPEN_CONVERSATION_VIA_NOTIFICATION, {
        notificationType,
      });
      this.$store.dispatch('notifications/read', {
        id: notification.id,
        primaryActorId,
        primaryActorType,
        unreadCount: this.meta.unreadCount,
      });
      this.$router.push({
        name: 'inbox_conversation',
        params: { conversation_id: conversationId },
      });
      this.$emit('close');
    },
    onClickNextPage() {
      if (!this.inLastPage) {
        const page = this.currentPage + 1;
        this.onPageChange(page);
      }
    },
    onClickPreviousPage() {
      if (!this.inFirstPage) {
        const page = this.currentPage - 1;
        this.onPageChange(page);
      }
    },
    onClickFirstPage() {
      if (!this.inFirstPage) {
        const page = 1;
        this.onPageChange(page);
      }
    },
    onClickLastPage() {
      if (!this.inLastPage) {
        const page = this.lastPage;
        this.onPageChange(page);
      }
    },
    onMarkAllDoneClick() {
      useTrack(ACCOUNT_EVENTS.MARK_AS_READ_NOTIFICATIONS);
      this.$store.dispatch('notifications/readAll');
    },
    openAudioNotificationSettings() {
      this.$router.push({ name: 'profile_settings_index' });
      this.closeNotificationPanel();
      this.$nextTick(() => {
        const audioSettings = document.getElementById(
          'profile-settings-notifications'
        );
        if (audioSettings) {
          // TODO [ref](https://github.com/chatwoot/chatwoot/pull/6233#discussion_r1069636890)
          audioSettings.scrollIntoView(
            { behavior: 'smooth', block: 'start' },
            150
          );
        }
      });
    },
    closeNotificationPanel() {
      this.$emit('close');
    },
  },
};
</script>

<template>
  <div class="modal-mask">
    <div
      v-on-clickaway="closeNotificationPanel"
      class="flex-col h-[90vh] w-[32.5rem] flex justify-between z-10 rounded-md shadow-md absolute bg-white dark:bg-slate-800 left-14 rtl:left-auto rtl:right-14 m-4"
    >
      <div
        class="flex flex-row items-center justify-between w-full px-6 pt-5 pb-3 border-b border-solid border-slate-50 dark:border-slate-700"
      >
        <div class="flex items-center">
          <span class="text-xl font-bold text-slate-800 dark:text-slate-100">
            {{ $t('NOTIFICATIONS_PAGE.UNREAD_NOTIFICATION.TITLE') }}
          </span>
          <span
            v-if="totalUnreadNotifications"
            class="px-2 py-1 ml-2 mr-2 font-semibold rounded-md text-slate-700 dark:text-slate-200 text-xxs bg-slate-50 dark:bg-slate-700"
          >
            {{ totalUnreadNotifications }}
          </span>
        </div>
        <div class="flex gap-2">
          <woot-button
            v-if="!noUnreadNotificationAvailable"
            color-scheme="primary"
            variant="smooth"
            size="tiny"
            :is-loading="uiFlags.isUpdating"
            @click="onMarkAllDoneClick"
          >
            {{ $t('NOTIFICATIONS_PAGE.MARK_ALL_DONE') }}
          </woot-button>
          <woot-button
            color-scheme="secondary"
            variant="smooth"
            size="tiny"
            icon="settings"
            @click="openAudioNotificationSettings"
          />
          <woot-button
            color-scheme="secondary"
            variant="link"
            size="tiny"
            icon="dismiss"
            @click="closeNotificationPanel"
          />
        </div>
      </div>
      <NotificationPanelList
        :notifications="getUnreadNotifications"
        :is-loading="uiFlags.isFetching"
        :on-click-notification="openConversation"
        :in-last-page="inLastPage"
        @close="closeNotificationPanel"
      />
      <div
        v-if="records.length !== 0"
        class="flex items-center justify-between px-5 py-1"
      >
        <div class="flex">
          <woot-button
            size="medium"
            variant="clear"
            color-scheme="secondary"
            :is-disabled="inFirstPage"
            @click="onClickFirstPage"
          >
            <fluent-icon icon="chevron-left" size="16" />
            <fluent-icon
              icon="chevron-left"
              size="16"
              class="rtl:-mr-3 ltr:-ml-3"
            />
          </woot-button>
          <woot-button
            color-scheme="secondary"
            variant="clear"
            size="medium"
            icon="chevron-left"
            :disabled="inFirstPage"
            @click="onClickPreviousPage"
          />
        </div>
        <span class="font-semibold text-xxs text-slate-500 dark:text-slate-400">
          {{ currentPage }} - {{ lastPage }}
        </span>
        <div class="flex">
          <woot-button
            color-scheme="secondary"
            variant="clear"
            size="medium"
            icon="chevron-right"
            :disabled="inLastPage"
            @click="onClickNextPage"
          />
          <woot-button
            size="medium"
            variant="clear"
            color-scheme="secondary"
            :disabled="inLastPage"
            @click="onClickLastPage"
          >
            <fluent-icon icon="chevron-right" size="16" />
            <fluent-icon
              icon="chevron-right"
              size="16"
              class="rtl:-mr-3 ltr:-ml-3"
            />
          </woot-button>
        </div>
      </div>
      <div v-else />
    </div>
  </div>
</template>
