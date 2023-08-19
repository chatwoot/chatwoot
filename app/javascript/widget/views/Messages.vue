<template>
  <div
    class="flex flex-col flex-1 pb-2 overflow-hidden rounded-b-lg"
    :class="$dm('bg-slate-25', 'dark:bg-slate-800')"
  >
    <div class="flex flex-1 overflow-auto">
      <conversation-wrap :grouped-messages="groupedMessages" />
    </div>
    <div class="px-5">
      <chat-footer />
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import darkModeMixin from 'widget/mixins/darkModeMixin';

import ChatFooter from '../components/ChatFooter.vue';
import ConversationWrap from '../components/ConversationWrap.vue';

export default {
  components: { ChatFooter, ConversationWrap },
  mixins: [darkModeMixin],
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
