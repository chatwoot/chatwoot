<template>
  <div class="conversation--container">
    <div class="conversation-wrap">
      <ChatMessage
        v-for="message in messages"
        :key="message.id"
        :message="message"
      />
    </div>
    <branding></branding>
  </div>
</template>

<script>
import Branding from 'widget/components/Branding.vue';
import ChatMessage from 'widget/components/ChatMessage.vue';

export default {
  name: 'ConversationWrap',
  components: {
    Branding,
    ChatMessage,
  },
  props: {
    messages: Object,
  },
  mounted() {
    this.scrollToBottom();
  },
  updated() {
    this.scrollToBottom();
  },
  methods: {
    scrollToBottom() {
      const container = this.$el;
      container.scrollTop =
        container.scrollHeight < this.minScrollHeight
          ? this.minScrollHeight
          : container.scrollHeight;
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/woot.scss';

.conversation--container {
  display: flex;
  flex-direction: column;
  flex: 1;
  overflow-y: auto;
}

.conversation-wrap {
  flex: 1;
  padding: $space-large $space-small $zero $space-small;
}
</style>
