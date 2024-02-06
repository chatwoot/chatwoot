<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <inbox-list
      v-show="showConversationList"
      :conversation-id="conversationId"
      :is-on-expanded-layout="isOnExpandedLayout"
    />
    <div v-if="showInboxMessageView" class="flex flex-col w-full h-full">
      <inbox-item-header
        :total-length="totalNotifications"
        :current-index="activeNotificationIndex"
        :active-notification="activeNotification"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <conversation-box
        class="h-[calc(100%-56px)]"
        is-inbox-view
        :inbox-id="inboxId"
        :is-contact-panel-open="isContactPanelOpen"
        :is-on-expanded-layout="isOnExpandedLayout"
        @contact-panel-toggle="onToggleContactPanel"
      />
    </div>
    <div
      v-if="!showInboxMessageView && !isOnExpandedLayout"
      class="text-center bg-slate-25 dark:bg-slate-800 justify-center w-full h-full flex items-center"
    >
      <span v-if="uiFlags.isFetching" class="spinner mt-4 mb-4" />
      <div v-else class="flex flex-row items-center gap-1">
        <fluent-icon
          icon="mail-inbox"
          size="18"
          class="text-slate-700 dark:text-slate-400"
        />
        <span class="text-slate-700 text-sm font-medium dark:text-slate-400">
          {{ $t('INBOX.LIST.NOTE') }}
        </span>
      </div>
    </div>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import InboxList from './InboxList.vue';
import InboxItemHeader from './components/InboxItemHeader.vue';
import ConversationBox from 'dashboard/components/widgets/conversation/ConversationBox.vue';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import wootConstants from 'dashboard/constants/globals';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export default {
  components: {
    InboxList,
    InboxItemHeader,
    ConversationBox,
  },
  mixins: [uiSettingsMixin],
  props: {
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    conversationId: {
      type: [String, Number],
      default: 0,
    },
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
      notifications: 'notifications/getNotifications',
      currentChat: 'getSelectedChat',
      allConversation: 'getAllConversations',
      uiFlags: 'notifications/getUIFlags',
    }),
    activeNotification() {
      return this.notifications.find(
        n => n.primary_actor.id === Number(this.conversationId)
      );
    },
    isInboxViewEnabled() {
      return this.$store.getters['accounts/isFeatureEnabledGlobally'](
        this.currentAccountId,
        FEATURE_FLAGS.INBOX_VIEW
      );
    },
    showConversationList() {
      return this.isOnExpandedLayout ? !this.conversationId : true;
    },
    isFetchingInitialData() {
      return this.uiFlags.isFetching && !this.notifications.length;
    },
    showInboxMessageView() {
      return (
        Boolean(this.conversationId) &&
        Boolean(this.currentChat.id) &&
        !this.isFetchingInitialData
      );
    },
    totalNotifications() {
      return this.notifications?.length ?? 0;
    },
    activeNotificationIndex() {
      const conversationId = Number(this.conversationId);
      const notificationIndex = this.notifications.findIndex(
        n => n.primary_actor.id === conversationId
      );
      return notificationIndex >= 0 ? notificationIndex + 1 : 0;
    },
    isOnExpandedLayout() {
      const {
        LAYOUT_TYPES: { CONDENSED },
      } = wootConstants;
      const { conversation_display_type: conversationDisplayType = CONDENSED } =
        this.uiSettings;
      return conversationDisplayType !== CONDENSED;
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
      handler() {
        this.fetchConversationById();
      },
    },
  },
  mounted() {
    // Open inbox view if inbox view feature is enabled, else redirect to dashboard
    // TODO: Remove this code once inbox view feature is enabled for all accounts
    if (!this.isInboxViewEnabled) {
      this.$router.push({
        name: 'home',
      });
    }
  },
  methods: {
    async fetchConversationById() {
      if (!this.conversationId) return;
      const chat = this.findConversation();
      if (!chat) {
        await this.$store.dispatch('getConversation', this.conversationId);
      }
      this.setActiveChat();
    },
    setActiveChat() {
      const selectedConversation = this.findConversation();
      if (!selectedConversation) return;
      this.$store
        .dispatch('setActiveChat', { data: selectedConversation })
        .then(() => {
          bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        });
    },
    findConversation() {
      const conversationId = Number(this.conversationId);
      return this.allConversation.find(c => c.id === conversationId);
    },
    navigateToConversation(activeIndex, direction) {
      const indexOffset = direction === 'next' ? 0 : -2;
      const targetNotification = this.notifications[activeIndex + indexOffset];
      if (targetNotification) {
        const {
          id,
          primary_actor_id: primaryActorId,
          primary_actor_type: primaryActorType,
          primary_actor: { id: conversationId, meta: { unreadCount } = {} },
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
          params: { conversation_id: conversationId },
        });
      }
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
