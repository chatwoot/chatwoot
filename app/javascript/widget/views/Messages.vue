<script>
import { mapGetters } from 'vuex';

import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';
import NoConversationWelcome from '../components/NoConversationWelcome.vue';

export default {
  components: { ChatFooter, ConversationWrap, NoConversationWelcome },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      conversationSize: 'conversation/getConversationSize',
    }),
    hasMessages() {
      return (
        this.conversationSize > 0 &&
        this.groupedMessages &&
        this.groupedMessages.length > 0
      );
    },
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
};
</script>

<template>
  <div
    class="flex flex-col flex-1 overflow-hidden rounded-b-lg bg-n-slate-2 dark:bg-n-solid-1"
  >
    <div v-if="hasMessages" class="flex flex-1 overflow-auto">
      <ConversationWrap :grouped-messages="groupedMessages" />
    </div>
    <NoConversationWelcome v-else />
    <ChatFooter class="px-5" />
  </div>
</template>
