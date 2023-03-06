<template>
  <div class="flex flex-col flex-1 overflow-hidden">
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap :grouped-messages="groupedMessages" />
    </div>
    <quick-replies :is-visible="hasQuickRepliesOptions" />
    <div class="px-5 py-5">
      <chat-footer />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';
import QuickReplies from '../components/QuickReplies.vue';

export default {
  components: { ChatFooter, ConversationWrap, QuickReplies },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      quickRepliesOptions: 'conversation/getQuickRepliesOptions',
    }),
    hasQuickRepliesOptions() {
      return Boolean(this.quickRepliesOptions.length);
    },
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
};
</script>
