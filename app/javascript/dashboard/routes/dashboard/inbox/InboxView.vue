<script>
import { mapGetters } from 'vuex';
import { useTrack } from 'dashboard/composables';
import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import InboxEmptyState from './InboxEmptyState.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: {
    InboxItemHeader,
    InboxEmptyState,
    ConversationBox,
  },
  setup() {
    const { uiSettings, updateUISettings } = useUISettings();

    return {
      uiSettings,
      updateUISettings,
    };
  },
  data() {
    return {
      isConversationLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      notification: 'notifications/getFilteredNotifications',
      currentChat: 'getSelectedChat',
      activeNotificationById: 'notifications/getNotificationById',
      conversationById: 'getConversationById',
      uiFlags: 'notifications/getUIFlags',
      meta: 'notifications/getMeta',
    }),
    notifications() {
      return this.notification({
        sortOrder: this.activeSortOrder,
      });
    },
    inboxId() {
      return Number(this.$route.params.inboxId);
    },
    notificationId() {
      return Number(this.$route.params.notification_id);
    },
    activeNotification() {
      return this.activeNotificationById(this.notificationId);
    },
    conversationId() {
      return this.activeNotification?.primary_actor?.id;
    },
    totalNotificationCount() {
      return this.meta.count;
    },
    showEmptyState() {
      return (
        !this.conversationId ||
        (!this.notifications?.length && this.uiFlags.isFetching)
      );
    },
    activeNotificationIndex() {
      return this.notifications?.findIndex(n => n.id === this.notificationId);
    },
    activeSortOrder() {
      const { inbox_filter_by: filterBy = {} } = this.uiSettings;
      const { sort_by: sortBy } = filterBy;
      return sortBy || 'desc';
    },
    isContactPanelOpen() {
      if (this.currentChat.id) {
        const { is_contact_sidebar_open: isContactSidebarOpen } =
          this.uiSettings;
        return isContactSidebarOpen;
      }
      return false;
    },
  },
  watch: {
    conversationId: {
      immediate: true,
      handler(newVal, oldVal) {
        if (newVal !== oldVal) {
          this.fetchConversationById();
        }
      },
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    async fetchConversationById() {
      if (!this.notificationId || !this.conversationId) return;
      this.$store.dispatch('clearSelectedState');
      const existingChat = this.findConversation();
      if (existingChat) {
        this.setActiveChat(existingChat);
        return;
      }
      this.isConversationLoading = true;
      await this.$store.dispatch('getConversation', this.conversationId);
      this.setActiveChat();
      this.isConversationLoading = false;
    },
    setActiveChat() {
      const selectedConversation = this.findConversation();
      if (!selectedConversation) return;
      this.$store
        .dispatch('setActiveChat', { data: selectedConversation })
        .then(() => {
          emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        });
    },
    findConversation() {
      return this.conversationById(this.conversationId);
    },
    navigateToConversation(activeIndex, direction) {
      let updatedIndex;
      if (direction === 'prev' && activeIndex) {
        updatedIndex = activeIndex - 1;
      } else if (
        direction === 'next' &&
        activeIndex < this.totalNotificationCount
      ) {
        updatedIndex = activeIndex + 1;
      }
      const targetNotification = this.notifications[updatedIndex];
      if (targetNotification) {
        this.openNotification(targetNotification);
      }
    },
    openNotification(notification) {
      const {
        id,
        primary_actor_id: primaryActorId,
        primary_actor_type: primaryActorType,
        primary_actor: { meta: { unreadCount } = {} },
        notification_type: notificationType,
      } = notification;

      useTrack(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
        notificationType,
      });

      this.$store.dispatch('notifications/read', {
        id,
        primaryActorId,
        primaryActorType,
        unreadCount,
      });

      this.$router.push({
        name: 'inbox_view_conversation',
        params: { notification_id: id },
      });
    },
    onClickNext() {
      this.navigateToConversation(this.activeNotificationIndex, 'next');
    },
    onClickPrev() {
      this.navigateToConversation(this.activeNotificationIndex, 'prev');
    },
    onToggleContactPanel() {
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactPanelOpen,
      });
    },
  },
};
</script>

<template>
  <div class="h-full w-full md:w-[calc(100%-360px)]">
    <div v-if="showEmptyState" class="flex w-full h-full">
      <InboxEmptyState
        :empty-state-message="$t('INBOX.LIST.NO_MESSAGES_AVAILABLE')"
      />
    </div>
    <div v-else class="flex flex-col w-full h-full">
      <InboxItemHeader
        class="flex-1"
        :total-length="totalNotificationCount"
        :current-index="activeNotificationIndex"
        :active-notification="activeNotification"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <div
        v-if="isConversationLoading"
        class="flex items-center h-[calc(100%-56px)] justify-center bg-slate-25 dark:bg-slate-800"
      >
        <span class="my-4 spinner" />
      </div>
      <ConversationBox
        v-else
        class="h-[calc(100%-56px)]"
        is-inbox-view
        :inbox-id="inboxId"
        :is-contact-panel-open="isContactPanelOpen"
        :is-on-expanded-layout="false"
        @contact-panel-toggle="onToggleContactPanel"
      />
    </div>
  </div>
</template>
