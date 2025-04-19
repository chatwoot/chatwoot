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
      const id = this.$route.params.notification_id;
      return id ? Number(id) : null;
    },
    activeNotification() {
      return this.notificationId ? this.activeNotificationById(this.notificationId) : null;
    },
    totalNotificationCount() {
      return this.meta.count;
    },
    showEmptyState() {
      return (
        !this.notificationId ||
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
      if (this.currentChat?.id) {
        const { is_contact_sidebar_open: isContactSidebarOpen } =
          this.uiSettings;
        return isContactSidebarOpen;
      }
      return false;
    },
  },
  watch: {
    notificationId: {
      handler(newId, oldId) {
        if (newId !== oldId && oldId !== null) {
          console.log(`~~~ [InboxView]: notificationId changed from ${oldId} to ${newId}. Clearing state.`);
          this.$store.dispatch('clearSelectedState');
        }
        this.isConversationLoading = !!newId;
      },
      immediate: true,
    },
    activeNotification: {
      handler(newNotification) {
        if (newNotification && newNotification.id === this.notificationId) {
          const conversationId = newNotification.primary_actor?.id;
          if (conversationId) {
            if (this.currentChat?.id !== conversationId) {
               this.fetchConversation(conversationId);
            } else {
               this.isConversationLoading = false;
            }
          } else {
            console.warn(`~~~ [InboxView]: activeNotification watcher - Notification ${this.notificationId} found, but missing primary_actor.id.`);
            this.isConversationLoading = false;
          }
        } else if (this.notificationId && !newNotification) {
           console.log(`~~~ [InboxView]: activeNotification watcher - Waiting for notification ${this.notificationId} to load into store...`);
           this.isConversationLoading = true;
        } else {
           this.isConversationLoading = false;
        }
      },
      deep: true,
      immediate: true,
    }
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    async fetchConversation(conversationId) {
      console.log(
        `~~ [InboxView]: Fetching conversation ${conversationId} (Notification: ${this.notificationId})`
      );
      if (!this.notificationId || !conversationId) {
         this.isConversationLoading = false;
         return;
      }

      const existingChat = this.findConversation(conversationId);
      if (existingChat) {
         if (this.currentChat?.id !== conversationId) {
            this.setActiveChat(existingChat);
         } else {
         }
         this.isConversationLoading = false;
         return;
      }

      this.isConversationLoading = true;
      try {
        await this.$store.dispatch('getConversation', conversationId);
        this.$nextTick(() => {
           const fetchedChat = this.findConversation(conversationId);
           if (fetchedChat) {
              this.setActiveChat(fetchedChat);
           } else {
              console.error(`~~ [InboxView]: Failed to find conversation ${conversationId} in store after fetch.`);
           }
           this.isConversationLoading = false;
        });
      } catch (error) {
         console.error(`~~ [InboxView]: Error fetching conversation ${conversationId}:`, error);
         this.isConversationLoading = false;
      }
    },
    setActiveChat(chatToSet) {
      if (!chatToSet) return;
      if (this.currentChat?.id === chatToSet.id) {
         return;
      }
      this.$store
        .dispatch('setActiveChat', { data: chatToSet })
        .then(() => {
          emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        });
    },
    findConversation(conversationId) {
      return this.conversationById(conversationId);
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
  <div class="h-full w-full xl:w-[calc(100%-400px)]">
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
        class="h-[calc(100%-56px)] [&.conversation-details-wrap]:!border-0"
        is-inbox-view
        :inbox-id="inboxId"
        :is-contact-panel-open="isContactPanelOpen"
        :is-on-expanded-layout="false"
        @contact-panel-toggle="onToggleContactPanel"
      />
    </div>
  </div>
</template>
