<template>
  <div
    class="flex flex-col flex-1 overflow-hidden rounded-b-lg bg-slate-25 dark:bg-slate-800"
  >
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap :grouped-messages="groupedMessages" />
    </div>
    <chat-footer class="px-5" />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

export default {
  components: { ChatFooter, ConversationWrap },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
    }),
  },
  mounted() {
    this.$store.dispatch('conversation/setUserLastSeen');
  },
};
</script>
