<template>
  <div class="flex flex-1 items-center h-full bg-black-25 justify-center">
    <div>
      <conversation-item
        v-for="conversation in allConversations"
        :key="conversation.id"
        :conversation="conversation"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import ConversationItem from 'widget/components/ConversationItem';

export default {
  name: 'Conversations',
  components: {
    ConversationItem,
  },
  props: {},
  data() {
    return {};
  },
  computed: {
    ...mapGetters({
      user: 'contacts/getCurrentUser',
      allConversations: 'conversationV2/allConversations',
    }),
  },
};
</script>
