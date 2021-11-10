<template>
  <unread-messages
    :messages="allMessages"
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
      campaign: 'campaign/getActiveCampaign',
      lastConversation: 'conversationV2/lastActiveConversationId',
    }),
    allMessages() {
      const { sender, id: campaignId, message: content } = this.campaign;
      return [
        {
          content,
          sender,
          campaignId,
        },
      ];
    },
  },
};
</script>
