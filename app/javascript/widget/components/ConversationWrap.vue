<template>
  <section class="conversation-wrap">
    <ChatMessage
      v-for="message in messages"
      :key="message.id"
      :message="message"
    />
    <branding></branding>
  </section>
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
