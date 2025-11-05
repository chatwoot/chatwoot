<script>
import { mapGetters } from 'vuex';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import ChatList from '../../../components/ChatList.vue';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox.vue';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CmdBarConversationSnooze from 'dashboard/routes/dashboard/commands/CmdBarConversationSnooze.vue';
import { emitter } from 'shared/helpers/mitt';
import ConversationSidebar from 'dashboard/components/widgets/conversation/ConversationSidebar.vue';
import { Splitpanes, Pane } from 'splitpanes';
import 'splitpanes/dist/splitpanes.css';

export default {
  components: {
    ChatList,
    ConversationBox,
    CmdBarConversationSnooze,
    ConversationSidebar,
    Splitpanes,
    Pane,
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
    const { uiSettings, updateUISettings } = useUISettings();
    const { accountId } = useAccount();

    return {
      uiSettings,
      updateUISettings,
      accountId,
    };
  },
  data() {
    return {
      showSearchModal: false,
      splitpaneSizes: {
        chatList: 15,
        conversationBox: 65,
        sidebar: 20,
      },
      isLayoutLocked: false,
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
    isOnExpandedLayout() {
      const {
        LAYOUT_TYPES: { CONDENSED },
      } = wootConstants;
      const { conversation_display_type: conversationDisplayType = CONDENSED } =
        this.uiSettings;
      return conversationDisplayType !== CONDENSED;
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
    this.loadSplitpaneSizes();
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
        if (
          !selectedConversation ||
          selectedConversation.id === this.currentChat.id
        ) {
          return;
        }
        const { messageId } = this.$route.query;
        this.$store
          .dispatch('setActiveChat', {
            data: selectedConversation,
            after: messageId,
          })
          .then(() => {
            emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
            // Auto-open contact sidebar when selecting a conversation
            this.updateUISettings({
              is_contact_sidebar_open: true,
              is_copilot_panel_open: false,
            });
          });
      } else {
        this.$store.dispatch('clearSelectedState');
      }
    },
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
    loadSplitpaneSizes() {
      const savedSizes = localStorage.getItem('splitpane_sizes');
      if (savedSizes) {
        try {
          const sizes = JSON.parse(savedSizes);
          this.splitpaneSizes = sizes;
          this.isLayoutLocked = true;
        } catch {
          // Failed to parse, use default sizes
        }
      }
    },
    saveSplitpaneSizes() {
      localStorage.setItem(
        'splitpane_sizes',
        JSON.stringify(this.splitpaneSizes)
      );
    },
    removeSavedSizes() {
      localStorage.removeItem('splitpane_sizes');
    },
    onSplitpaneResize({ panes }) {
      if (panes && panes.length === 3) {
        this.splitpaneSizes.chatList = panes[0]?.size;
        this.splitpaneSizes.conversationBox = panes[1]?.size;
        this.splitpaneSizes.sidebar = panes[2]?.size;
      }
    },
    toggleLayoutLock() {
      if (this.isLayoutLocked) {
        this.removeSavedSizes();
        this.isLayoutLocked = false;
      } else {
        this.saveSplitpaneSizes();
        this.isLayoutLocked = true;
      }
    },
  },
};
</script>

<template>
  <section class="flex w-full h-full min-w-0 relative">
    <Splitpanes
      class="w-full h-full"
      :class="{ 'splitpanes-locked': isLayoutLocked }"
      @resized="onSplitpaneResize"
    >
      <Pane
        :size="splitpaneSizes.chatList"
        min-size="10"
        max-size="20"
        class="flex h-full"
      >
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
      </Pane>
      <Pane
        :size="splitpaneSizes.conversationBox"
        min-size="30"
        max-size="80"
        class="flex h-full"
      >
        <ConversationBox
          :inbox-id="inboxId"
          :is-on-expanded-layout="isOnExpandedLayout"
        />
      </Pane>
      <Pane
        :size="splitpaneSizes.sidebar"
        min-size="15"
        max-size="50"
        class="flex h-full"
      >
        <ConversationSidebar :current-chat="currentChat" />
      </Pane>
    </Splitpanes>
    <button
      type="button"
      class="absolute top-4 right-4 z-50 flex items-center gap-2 px-3 py-1.5 text-xs font-medium bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-md shadow-sm hover:bg-slate-50 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 transition-colors outline-none"
      :class="{
        'border-woot-500 dark:border-woot-400': isLayoutLocked,
      }"
      @click="toggleLayoutLock"
    >
      <svg
        v-if="isLayoutLocked"
        class="w-3.5 h-3.5"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
        />
      </svg>
      <svg
        v-else
        class="w-3.5 h-3.5"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"
        />
      </svg>
      {{
        isLayoutLocked
          ? $t('CONVERSATION.UNLOCK_LAYOUT')
          : $t('CONVERSATION.LOCK_LAYOUT')
      }}
    </button>
    <CmdBarConversationSnooze />
  </section>
</template>

<style>
/* Splitpanes customization - minimal styles for resizer appearance */
.splitpanes__splitter {
  background-color: rgb(229 231 235);
  transition: background-color 0.2s;
  position: relative;
}

.splitpanes__splitter:hover {
  background-color: rgb(209 213 219);
}

.splitpanes__splitter::before {
  content: '';
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%);
  width: 4px;
  height: 40px;
  background-color: rgb(156 163 175);
  border-radius: 2px;
  opacity: 0;
  transition: opacity 0.2s;
}

.splitpanes__splitter:hover::before {
  opacity: 1;
}

.splitpanes--vertical > .splitpanes__splitter {
  width: 6px;
  border-left: 1px solid rgb(229 231 235);
  border-right: 1px solid rgb(229 231 235);
  cursor: col-resize;
}

/* Disable resizing when locked */
.splitpanes-locked .splitpanes__splitter {
  pointer-events: none;
  cursor: default;
  opacity: 0.5;
}

.splitpanes-locked .splitpanes__splitter:hover {
  background-color: rgb(229 231 235);
}

.splitpanes-locked .splitpanes__splitter::before {
  opacity: 0 !important;
}
</style>
