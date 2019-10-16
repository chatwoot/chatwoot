<template>
  <div class="home">
    <div class="header-wrap">
      <ChatHeaderExpanded />
    </div>
    <div class="conversation-wrap">
      <ConversationWrap :messages="getConversationById(lastConversation)" />
    </div>
    <div class="footer-wrap">
      <ChatFooter :on-send-message="handleSendMessage" />
    </div>
  </div>
</template>

<script>
import { mapActions, mapState, mapGetters } from 'vuex';

import { DEFAULT_CONVERSATION } from 'widget/store/modules/conversation';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';

export default {
  name: 'Home',
  components: {
    ChatFooter,
    ChatHeaderExpanded,
    ConversationWrap,
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    handleSendMessage(content) {
      const { inboxId, accountId, contactId, lastConversation } = this;
      console.log(lastConversation);
      const conversationId = lastConversation || DEFAULT_CONVERSATION;
      this.sendMessage({
        inboxId,
        accountId,
        contactId,
        content,
        conversationId,
      });
    },
  },
  computed: {
    ...mapState('auth', ['accountId', 'inboxId', 'lastConversation']),
    ...mapGetters('auth', ['contactId']),
    ...mapGetters('conversation', ['getConversationById']),
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.home {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  background: $color-background;

  .header-wrap {
    flex-shrink: 0;
  }

  .conversation-wrap {
    flex: 1;
    overflow: auto;
  }

  .footer-wrap {
    flex-shrink: 0;
  }
}
</style>
