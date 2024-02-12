<template>
  <section class="flex w-full h-full bg-white dark:bg-slate-900">
    <inbox-list
      v-show="showConversationList"
      :notification-id="notificationId"
      :is-on-expanded-layout="isOnExpandedLayout"
    />
    <div
      v-if="showInboxMessageView"
      class="flex flex-col h-full"
      :class="isOnExpandedLayout ? 'w-full' : 'w-[calc(100%-360px)]'"
    >
      <inbox-item-header
        :total-length="totalNotifications"
        :current-index="activeNotificationIndex"
        :active-notification="activeNotification"
        @next="onClickNext"
        @prev="onClickPrev"
      />
      <div v-if="isLoadingConversation" class="h-[calc(100%-56px)] w-full">
        <span class="spinner mt-4 mb-4 h-full w-full" />
      </div>
      <conversation-box
        v-else
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
      <div v-else class="flex flex-col items-center gap-2">
        <fluent-icon
          icon="mail-inbox"
          size="40"
          class="text-slate-600 dark:text-slate-400"
        />
        <span class="text-slate-500 text-sm font-medium dark:text-slate-300">
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
import resizeListenerMixin from 'shared/mixins/resizeListenerMixin';
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
  mixins: [uiSettingsMixin, resizeListenerMixin],
  props: {
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    notificationId: {
      type: [String, Number],
      default: 0,
    },
  },
  data() {
    return {
      isOnExpandedLayout: false,
      isLoadingConversation: false,
    };
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
      return this.notifications.find(n => n.id === Number(this.notificationId));
    },
    conversationId() {
      return this.activeNotification?.primary_actor.id;
    },
    isInboxViewEnabled() {
      return this.$store.getters['accounts/isFeatureEnabledGlobally'](
        this.currentAccountId,
        FEATURE_FLAGS.INBOX_VIEW
      );
    },
    showConversationList() {
      return this.isOnExpandedLayout ? !this.notificationId : true;
    },
    isFetchingInitialData() {
      return this.uiFlags.isFetching && !this.notifications.length;
    },
    showInboxMessageView() {
      return Boolean(this.notificationId) && !this.isFetchingInitialData;
    },
    totalNotifications() {
      return this.notifications?.length ?? 0;
    },
    activeNotificationIndex() {
      const notificationIndex = this.notifications.findIndex(
        n => n.id === Number(this.notificationId)
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
    // Open inbox view if inbox view feature is enabled, else redirect to dashboard
    // TODO: Remove this code once inbox view feature is enabled for all accounts
    if (!this.isInboxViewEnabled) {
      this.$router.push({
        name: 'home',
      });
    }
    this.$store.dispatch('agents/get');
    this.handleResize();
  },
  methods: {
    handleResize() {
      const { SMALL_SCREEN_BREAKPOINT } = wootConstants;
      if (window.innerWidth <= SMALL_SCREEN_BREAKPOINT) {
        this.isOnExpandedLayout = true;
      } else {
        this.isOnExpandedLayout = false;
      }
    },
    async fetchConversationById() {
      if (!this.notificationId || !this.conversationId) return;
      this.isLoadingConversation = true;
      this.$store.dispatch('clearSelectedState');
      const existingChat = this.findConversation();
      if (existingChat) {
        this.setActiveChat(existingChat);
        this.isLoadingConversation = false;
        return;
      }
      await this.$store.dispatch('getConversation', this.conversationId);
      this.setActiveChat();
      this.isLoadingConversation = false;
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
      return this.allConversation.find(
        c => c.id === Number(this.conversationId)
      );
    },
    navigateToConversation(activeIndex, direction) {
      const indexOffset = direction === 'next' ? 0 : -2;
      const targetNotification = this.notifications[activeIndex + indexOffset];
      if (targetNotification) {
        const {
          id,
          primary_actor_id: primaryActorId,
          primary_actor_type: primaryActorType,
          primary_actor: { meta: { unreadCount } = {} },
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
          params: { notification_id: id },
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
