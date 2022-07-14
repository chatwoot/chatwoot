<template>
  <section class="conversation-page">
    <chat-list
      :show="shouldShowChatList"
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      :conversation-type="conversationType"
      :folders-id="foldersId"
      :is-list-view-display="isListViewDisplay"
      @conversation-load="onConversationLoad"
    >
      <pop-over-search @toggle-view="toggleView" />
    </chat-list>
    <conversation-box
      v-if="shouldShowMessageView"
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      :is-list-view-display="isListViewDisplay"
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
    shouldShowChatList() {
      return this.isListViewDisplay ? !this.conversationId : true;
    },
    shouldShowMessageView() {
      if (this.conversationId) {
        return true;
      }
      return !this.isListViewDisplay;
    },
    isListViewDisplay() {
      const {
        conversation_display_type: conversationDisplayType = 'list',
      } = this.uiSettings;
      return conversationDisplayType === 'list';
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
    toggleView() {
      const {
        conversation_display_type: conversationDisplayType = 'list',
      } = this.uiSettings;
      const newViewType = conversationDisplayType === 'list' ? 'card' : 'list';
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
        const chat = this.findConversation();
        if (!chat) {
          return;
        }
        this.$store.dispatch('setActiveChat', chat).then(() => {
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
