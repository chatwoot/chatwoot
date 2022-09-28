<template>
  <section class="conversation-page">
    <chat-list
      :show-conversation-list="showConversationList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-on-expanded-layout="isOnExpandedLayout"
      @conversation-load="onConversationLoad"
    >
      <pop-over-search
        :is-on-expanded-layout="isOnExpandedLayout"
        @toggle-conversation-layout="toggleConversationLayout"
      />
    </chat-list>
    <conversation-box
      v-if="showMessageView"
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      :is-on-expanded-layout="isOnExpandedLayout"
      @contact-panel-toggle="onToggleContactPanel"
    />
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import ChatList from '../../../components/ChatList';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';
import PopOverSearch from './search/PopOverSearch';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import wootConstants from 'dashboard/constants';

export default {
  components: {
    ChatList,
    ConversationBox,
    PopOverSearch,
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
  data() {
    return {
      showSearchModal: false,
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
      const {
        conversation_display_type: conversationDisplayType = CONDENSED,
      } = this.uiSettings;
      return conversationDisplayType !== CONDENSED;
    },
    isContactPanelOpen() {
      if (this.currentChat.id) {
        const {
          is_contact_sidebar_open: isContactSidebarOpen,
        } = this.uiSettings;
        return isContactSidebarOpen;
      }
      return false;
    },
  },
  watch: {
    conversationId() {
      this.fetchConversationIfUnavailable();
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
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
        conversation_display_type: conversationDisplayType = LAYOUT_TYPES.CONDENSED,
      } = this.uiSettings;
      const newViewType =
        conversationDisplayType === LAYOUT_TYPES.CONDENSED
          ? LAYOUT_TYPES.EXPANDED
          : LAYOUT_TYPES.CONDENSED;
      this.updateUISettings({ conversation_display_type: newViewType });
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
        this.$store.dispatch('setActiveChat', selectedConversation).then(() => {
          bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        });
      } else {
        this.$store.dispatch('clearSelectedState');
      }
    },
    onToggleContactPanel() {
      this.updateUISettings({
        is_contact_sidebar_open: !this.isContactPanelOpen,
      });
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
<style lang="scss" scoped>
.conversation-page {
  display: flex;
  width: 100%;
  height: 100%;
}
</style>
