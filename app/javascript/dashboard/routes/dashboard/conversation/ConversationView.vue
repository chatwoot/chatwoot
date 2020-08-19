<template>
  <section class="app-content columns">
    <chat-list :conversation-inbox="inboxId" :label="label"></chat-list>
    <conversation-box
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contact-panel-toggle="onToggleContactPanel"
    >
    </conversation-box>
    <contact-panel
      v-if="isContactPanelOpen"
      :conversation-id="conversationId"
      :on-toggle="onToggleContactPanel"
    />
  </section>
</template>

<script>
/* eslint no-console: 0 */
import { mapGetters } from 'vuex';

import ChatList from '../../../components/ChatList';
import ContactPanel from './ContactPanel';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';

export default {
  components: {
    ChatList,
    ContactPanel,
    ConversationBox,
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
  },

  data() {
    return {
      panelToggleState: true,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
      currentChat: 'getSelectedChat',
    }),
    isContactPanelOpen: {
      get() {
        if (this.currentChat.id) {
          return this.panelToggleState;
        }
        return false;
      },
      set(val) {
        this.panelToggleState = val;
      },
    },
  },

  mounted() {
    this.$store.dispatch('labels/get');
    this.$store.dispatch('agents/get');

    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.fetchConversation();
      this.setActiveChat();
    });
  },

  methods: {
    initialize() {
      this.$store.dispatch('setActiveInbox', this.inboxId);
      this.setActiveChat();
    },

    fetchConversation() {
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
      this.isContactPanelOpen = !this.isContactPanelOpen;
    },
  },
};
</script>
