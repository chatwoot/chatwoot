<script>
import { provide } from 'vue';
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import {
  CONTACT_CONVERSATION_NAVIGATION,
  useContactConversationNavigation,
} from 'dashboard/composables/useContactConversationNavigation';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePendingAlert } from 'dashboard/composables';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import SidepanelSwitch from 'dashboard/components-next/Conversation/SidepanelSwitch.vue';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';

export default {
  components: {
    ChatList,
    ConversationBox,
    CmdBarConversationSnooze,
    SidepanelSwitch,
    ConversationSidebar,
  },
  beforeRouteLeave(to, from, next) {
    // Clear selected state if navigating away from a conversation to a route without a conversationId to prevent stale data issues
    // and resolves timing issues during navigation with conversation view and other screens
    if (this.conversationId) {
      this.$store.dispatch('clearSelectedState');
    }
    next(); // Continue with navigation
  },
  props: {
    inboxId: {
      type: [String, Number],
      default: 0,
    },
    conversationId: {
      type: [String, Number],
      default: 0,
    },
    label: {
      type: String,
      default: '',
    },
    teamId: {
      type: String,
      default: '',
    },
    conversationType: {
      type: String,
      default: '',
    },
    foldersId: {
      type: [String, Number],
      default: 0,
    },
  },
  setup() {
    const { uiSettings, updateUISettings, isOnExpandedLayout } =
      useUISettings();
    const { accountId } = useAccount();
    provide(
      CONTACT_CONVERSATION_NAVIGATION,
      useContactConversationNavigation()
    );

    return {
      uiSettings,
      updateUISettings,
      isOnExpandedLayout,
      accountId,
    };
  },
  data() {
    return {
      showSearchModal: false,
      // Tracks the messageId we've already scrolled to. `setActiveChat` re-runs
      // whenever the conversation list length or route state changes (incoming
      // cables, filters), so this keeps the query-driven scroll a one-shot and
      // stops it from yanking the viewport back on every list update.
      scrolledToMessageId: null,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
    }),
    showConversationList() {
      return this.isOnExpandedLayout ? !this.conversationId : true;
    },
    showMessageView() {
      return this.conversationId ? true : !this.isOnExpandedLayout;
    },
    shouldShowSidebar() {
      if (!this.currentChat.id) {
        return false;
      }

      const { is_contact_sidebar_open: isContactSidebarOpen } = this.uiSettings;
      return isContactSidebarOpen;
    },
  },
  watch: {
    conversationId() {
      // Switching conversations clears the consumed marker so a fresh
      // messageId on the next conversation is honored.
      this.scrolledToMessageId = null;
      this.fetchConversationIfUnavailable();
    },
  },

  created() {
    // Clear selected state early if no conversation is selected
    // This prevents child components from accessing stale data
    // and resolves timing issues during navigation
    // with conversation view and other screens
    if (!this.conversationId) {
      this.$store.dispatch('clearSelectedState');
    }
  },

  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('portals/index');
    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.setActiveChat();
    });
  },

  methods: {
    onConversationLoad() {
      this.fetchConversationIfUnavailable();
    },
    initialize() {
      this.$store.dispatch('setActiveInbox', this.inboxId);
      this.setActiveChat();
    },
    toggleConversationLayout() {
      const { LAYOUT_TYPES } = wootConstants;
      const {
        conversation_display_type:
          conversationDisplayType = LAYOUT_TYPES.CONDENSED,
      } = this.uiSettings;
      const newViewType =
        conversationDisplayType === LAYOUT_TYPES.CONDENSED
          ? LAYOUT_TYPES.EXPANDED
          : LAYOUT_TYPES.CONDENSED;
      this.updateUISettings({
        conversation_display_type: newViewType,
        previously_used_conversation_display_type: newViewType,
      });
    },
    fetchConversationIfUnavailable() {
      if (!this.conversationId) {
        return;
      }
      const chat = this.findConversation();
      if (!chat) {
        this.$store.dispatch('getConversation', this.conversationId);
      }
    },
    findConversation() {
      const conversationId = parseInt(this.conversationId, 10);
      const [chat] = this.chatList.filter(c => c.id === conversationId);
      return chat;
    },
    setActiveChat() {
      if (this.conversationId) {
        const selectedConversation = this.findConversation();
        // If conversation doesn't exist or selected conversation is same as the active
        // conversation, don't set active conversation.
        if (!selectedConversation) {
          return;
        }

        const { messageId } = this.$route.query;
        // The query messageId is a one-shot "jump to this message" instruction.
        // Treat it as actionable only the first time we see it; re-runs of this
        // method (list-length/route watchers) must not re-scroll to it.
        const shouldScrollToMessage =
          messageId && messageId !== this.scrolledToMessageId;

        // Same conversation but new messageId — fetch around that message
        if (selectedConversation.id === this.currentChat.id) {
          if (shouldScrollToMessage) {
            this.scrolledToMessageId = messageId;
            this.scrollToMessageById(messageId);
          }
          return;
        }

        if (shouldScrollToMessage) {
          this.scrolledToMessageId = messageId;
          const dismissSearch = usePendingAlert(
            this.$t('SCHEDULED_MESSAGES.ITEM.SEARCHING_MESSAGE')
          );
          this.$store
            .dispatch('setActiveChat', {
              data: selectedConversation,
              after: messageId,
            })
            .then(() => {
              dismissSearch();
              emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
            });
        } else {
          this.$store
            .dispatch('setActiveChat', {
              data: selectedConversation,
            })
            .then(() => {
              emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
            });
        }
      } else {
        this.$store.dispatch('clearSelectedState');
      }
    },
    async scrollToMessageById(messageId) {
      const dismissSearch = usePendingAlert(
        this.$t('SCHEDULED_MESSAGES.ITEM.SEARCHING_MESSAGE')
      );
      this.$store.commit('CLEAR_ALL_MESSAGES_LOADED', this.currentChat.id);
      try {
        await this.$store.dispatch('fetchPreviousMessages', {
          conversationId: this.currentChat.id,
          after: messageId,
          before: this.currentChat.messages?.[0]?.id,
        });
      } catch {
        // ignore fetch error — scroll handler will show alert if message not found
      }
      dismissSearch();
      emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
    },
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
  },
};
</script>

<template>
  <section class="flex w-full h-full min-w-0">
    <ChatList
      :show-conversation-list="showConversationList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @conversation-load="onConversationLoad"
    />
    <ConversationBox
      v-if="showMessageView"
      :inbox-id="inboxId"
      :is-on-expanded-layout="isOnExpandedLayout"
    >
      <SidepanelSwitch v-if="currentChat.id" />
    </ConversationBox>
    <ConversationSidebar v-if="shouldShowSidebar" :current-chat="currentChat" />
    <CmdBarConversationSnooze />
  </section>
</template>
