<template>
  <section class="app-content columns">
    <chat-list :conversation-inbox="inboxId"></chat-list>
    <conversation-box
      :inbox-id="inboxId"
      :is-contact-panel-open="isContactPanelOpen"
      @contactPanelToggle="onToggleContactPanel"
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
/* global bus */
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

  data() {
    return {
      panelToggleState: false,
    };
  },
  computed: {
    ...mapGetters({
      chatList: 'getAllConversations',
    }),
    isContactPanelOpen: {
      get() {
        if (this.conversationId) {
          return this.panelToggleState;
        }
        return false;
      },
      set(val) {
        this.panelToggleState = val;
      },
    },
  },
  props: ['inboxId', 'conversationId'],

  mounted() {
    this.initialize();
    this.$watch('$store.state.route', () => this.initialize());
    this.$watch('chatList.length', () => {
      this.fetchConversation();
      this.setActiveChat();
    });
  },

  methods: {
    initialize() {
      switch (this.$store.state.route.name) {
        case 'inbox_conversation':
          this.setActiveChat();
          break;
        case 'inbox_dashboard':
          if (this.inboxId) {
            this.$store.dispatch('setActiveInbox', this.inboxId);
          }
          break;
        case 'conversation_through_inbox':
          if (this.inboxId) {
            this.$store.dispatch('setActiveInbox', this.inboxId);
          }
          this.setActiveChat();
          break;
        default:
          this.$store.dispatch('setActiveInbox', null);
          this.$store.dispatch('clearSelectedState');
          break;
      }
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
      const chat = this.findConversation();
      if (!chat) return;
      this.$store.dispatch('setActiveChat', chat).then(() => {
        bus.$emit('scrollToMessage');
      });
    },
    onToggleContactPanel() {
      this.isContactPanelOpen = !this.isContactPanelOpen;
    },
  },
};
</script>
