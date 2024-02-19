<template>
  <div class="flex flex-col h-full w-full md:w-[calc(100%-360px)]">
    <inbox-item-header
      :total-length="totalNotifications"
      :current-index="activeNotificationPosition"
      :active-notification="activeNotification"
      @next="onClickNext"
      @prev="onClickPrev"
    />
    <conversation-box
      class="h-[calc(100%-56px)]"
      is-inbox-view
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      :is-on-expanded-layout="false"
      @contact-panel-toggle="onToggleContactPanel"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export default {
  components: {
    InboxItemHeader,
    ConversationBox,
  },
  mixins: [uiSettingsMixin],
  computed: {
    ...mapGetters({
      notifications: 'notifications/getNotifications',
      activeNotificationById: 'notifications/getActiveNotificationById',
      currentChat: 'getSelectedChat',
      conversationById: 'getConversationById',
      uiFlags: 'notifications/getUIFlags',
    }),
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
    totalNotifications() {
      return this.notifications?.length ?? 0;
    },
    activeNotificationPosition() {
      const notificationIndex = this.notifications.findIndex(
        n => n.id === this.notificationId
      );
      return notificationIndex >= 0 ? notificationIndex + 1 : 0;
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
      await this.$store.dispatch('getConversation', this.conversationId);
      this.setActiveChat();
    },
    setActiveChat(conversation = null) {
      const selectedConversation = conversation || this.findConversation();
      if (!selectedConversation) return;

      this.$store
        .dispatch('setActiveChat', { data: selectedConversation })
        .then(() => {
          bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        });
    },
    findConversation() {
      return this.conversationById(this.conversationId);
    },
    navigateToConversation(activeIndex, direction) {
      const indexOffset = direction === 'next' ? 0 : -2;
      const targetNotification = this.notifications[activeIndex + indexOffset];
      if (targetNotification) {
        const {
          id,
          primary_actor_id: primaryActorId,
          primary_actor_type: primaryActorType,
          primary_actor: { inbox_id: inboxId, meta: { unreadCount } = {} },
          notification_type: notificationType,
        } = targetNotification;

        this.$track(INBOX_EVENTS.OPEN_CONVERSATION_VIA_INBOX, {
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
          params: { inboxId, notification_id: id },
        });
      }
    },
    onClickNext() {
      this.navigateToConversation(this.activeNotificationPosition, 'next');
    },
    onClickPrev() {
      this.navigateToConversation(this.activeNotificationPosition, 'prev');
    },
    onToggleContactPanel() {
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactPanelOpen,
      });
    },
  },
};
</script>
