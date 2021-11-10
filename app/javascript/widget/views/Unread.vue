<template>
  <unread-messages
    :messages="unreadMessages"
    :unread-message-count="unreadMessageCount"
  />
</template>
<script>
import UnreadMessages from 'widget/components/UnreadMessages';
import { mapGetters } from 'vuex';

export default {
  name: 'Unread',
  components: {
    UnreadMessages,
  },
  props: {
    hasFetched: {
      type: Boolean,
      default: false,
    },
    unreadMessageCount: {
      type: Number,
      default: 0,
    },
    hideMessageBubble: {
      type: Boolean,
      default: false,
    },
    showUnreadView: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      unreadMessagesIn: 'conversationV2/unreadTextMessagesIn',
      lastActiveConversationId: 'conversationV2/lastActiveConversationId',
    }),
    unreadMessages() {
      const conversationId = this.lastActiveConversationId;
      if (!conversationId) return [];

      return this.unreadMessagesIn(conversationId);
    },
  },
};
</script>
