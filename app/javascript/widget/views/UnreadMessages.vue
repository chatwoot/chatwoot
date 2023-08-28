<template>
  <unread-message-list :messages="messages" @close="closeFullView" />
</template>

<script>
import { mapGetters } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';
import UnreadMessageList from '../components/UnreadMessageList.vue';

export default {
  name: 'UnreadMessages',
  components: {
    UnreadMessageList,
  },
  computed: {
    ...mapGetters({
      activeConversationId: 'conversationV3/lastActiveConversationId',
      messagesIn: 'conversationV3/unreadTextMessagesIn',
    }),
    messages() {
      return this.messagesIn(this.activeConversationId);
    },
  },
  methods: {
    closeFullView() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
      }
    },
  },
};
</script>
