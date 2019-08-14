<template>
  <section class="app-content columns">
    <chat-list :conversationInbox="inboxId" :pageTitle="$t('CHAT_LIST.TAB_HEADING')" ></chat-list>
    <conversation-box :inbox-id="inboxId"></conversation-box>
  </section>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';

import ChatList from '../../../components/ChatList';
import ConversationBox from '../../../components/widgets/conversation/ConversationBox';

export default {
  components: {
    ChatList,
    ConversationBox,
  },

  data() {
    return {
      pageTitle: this.$state,
    };
  },
  computed: {
    ...mapGetters({
      menuItems: 'getMenuItems',
      chatList: 'getAllConversations',
    }),
  },
  props: ['inboxId', 'conversationId'],

  mounted() {
    this.$watch('$store.state.route', () => {
      switch (this.$store.state.route.name) {
        case 'inbox_conversation':
          this.setActiveChat();
          break;
        case 'inbox_dashboard':
          if (this.inboxId) {
            this.$store.dispatch('setActiveInbox', this.inboxId);
          }
          break;
        default:
          this.$store.dispatch('setActiveInbox', null);
          break;
      }
    });
    this.$watch('chatList.length', () => {
      this.setActiveChat();
    });
  },

  methods: {
    setActiveChat() {
      const conversationId = parseInt(this.conversationId, 10);
      const [chat] = this.chatList.filter(c => c.id === conversationId);
      if (!chat) return;
      this.$store.dispatch('setActiveChat', chat).then(() => {
        bus.$emit('scrollToMessage');
      });
    },
  },
};
</script>
