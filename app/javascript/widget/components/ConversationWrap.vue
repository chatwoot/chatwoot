<template>
  <section class="conversation-wrap">
    <ChatMessage
      v-for="message in messages"
      :key="message.id"
      :message="message"
    />
  </section>
</template>

<script>
import ChatMessage from 'widget/components/ChatMessage.vue';

export default {
  name: 'ConversationWrap',
  components: {
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
