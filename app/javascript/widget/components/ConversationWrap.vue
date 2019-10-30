<template>
  <section class="conversation">
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
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.conversation {
  height: 100%;
}
</style>
