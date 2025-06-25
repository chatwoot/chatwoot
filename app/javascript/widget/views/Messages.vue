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

<template>
  <div class="flex flex-col flex-1 overflow-hidden">
    <div class="flex flex-1 overflow-auto">
      <ConversationWrap :grouped-messages="groupedMessages" />
    </div>
    <div class="px-5 py-5">
      <ChatFooter />
    </div>
  </div>
</template>
