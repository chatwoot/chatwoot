<template>
  <div class="home">
    <div class="header-wrap">
      <ChatHeaderExpanded v-if="isHeaderExpanded" />
      <ChatHeader v-else :title="getHeaderName" />
    </div>
    <ConversationWrap :grouped-messages="groupedMessages" />
    <div class="footer-wrap">
      <div class="input-wrap">
        <ChatFooter :on-send-message="handleSendMessage" />
      </div>
      <branding></branding>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';

import Branding from 'widget/components/Branding.vue';
import ChatFooter from 'widget/components/ChatFooter.vue';
import ChatHeaderExpanded from 'widget/components/ChatHeaderExpanded.vue';
import ChatHeader from 'widget/components/ChatHeader.vue';
import ConversationWrap from 'widget/components/ConversationWrap.vue';

export default {
  name: 'Home',
  components: {
    ChatFooter,
    ChatHeaderExpanded,
    ConversationWrap,
    ChatHeader,
    Branding,
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    handleSendMessage(content) {
      this.sendMessage({
        content,
      });
    },
  },
  computed: {
    ...mapGetters({
      groupedMessages: 'conversation/getGroupedConversation',
      conversationSize: 'conversation/getConversationSize',
    }),
    isHeaderExpanded() {
      return this.conversationSize === 0;
    },
    getHeaderName() {
      return window.chatwootWebChannel.website_name;
    },
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

  .footer-wrap {
    flex-shrink: 0;
    width: 100%;
    display: flex;
    flex-direction: column;
  }

  .input-wrap {
    padding: 0 $space-medium;
  }
}
</style>
