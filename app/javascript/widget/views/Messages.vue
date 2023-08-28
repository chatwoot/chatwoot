<template>
  <div class="flex flex-col flex-1 overflow-hidden">
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap :grouped-messages="groupedMessages" />
    </div>
    <div class="px-5">
      <chat-footer />
    </div>
  </div>
</template>
<script>
import { mapGetters, mapActions } from 'vuex';
import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

export default {
  components: { ChatFooter, ConversationWrap },
  computed: {
    ...mapGetters({
      activeConversationId: 'conversationV3/lastActiveConversationId',
      groupedMessagesIn: 'conversationV3/groupByMessagesIn',
    }),
    groupedMessages() {
      return this.groupedMessagesIn(this.activeConversationId);
    },
  },
  mounted() {
    this.setUserLastSeenIn({ conversationId: this.activeConversationId });
  },
  methods: {
    ...mapActions({
      setUserLastSeenIn: 'conversationV3/setUserLastSeenIn',
    }),
  },
};
</script>
