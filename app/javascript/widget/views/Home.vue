<template>
  <div class="home">
    <div class="header-wrap">
      <ChatHeaderExpanded />
    </div>
    <div class="conversation-wrap">
      <ConversationWrap :messages="getConversation" />
    </div>
    <div class="footer-wrap">
      <ChatFooter :on-send-message="handleSendMessage" />
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';

// import { DEFAULT_CONVERSATION } from 'widget/store/modules/conversation';
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
      this.sendMessage({
        content,
      });
    },
    scrollToBottom() {
      const container = this.$el.querySelector('.conversation-wrap');
      container.scrollTop = container.scrollHeight;
    },
  },
  computed: {
    ...mapGetters('conversation', ['getConversation']),
  },
  mounted() {
    this.scrollToBottom();
  },
  updated() {
    this.scrollToBottom();
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
    overflow-y: auto;
  }

  .footer-wrap {
    flex-shrink: 0;
  }
}
</style>
