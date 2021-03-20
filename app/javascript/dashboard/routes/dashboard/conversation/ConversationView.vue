<template>
  <section class="conversation-page">
    <chat-list
      :conversation-inbox="inboxId"
      :label="label"
      :team-id="teamId"
      @conversation-load="onConversationLoad"
    >
      <pop-over-search />
    </chat-list>
    <conversation-box
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contact-panel-toggle="onToggleContactPanel"
    >
    </conversation-box>
  </section>
</template>

<script>
import { mapGetters } from 'vuex';
import ChatList from '../../../components/ChatList';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';
import PopOverSearch from './search/PopOverSearch';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

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
          bus.$emit('scrollToMessage');
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
