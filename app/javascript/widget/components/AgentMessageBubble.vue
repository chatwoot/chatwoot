<template>
  <div class="chat-bubble agent">
    <span v-html="formatMessage(message)"></span>
    <email-input
      v-if="shouldShowInput"
      :message-id="messageId"
      :message-content-attributes="messageContentAttributes"
    />
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import EmailInput from './template/EmailInput';

export default {
  name: 'AgentMessageBubble',
  components: {
    EmailInput,
  },
  mixins: [messageFormatterMixin],
  props: {
    message: String,
    contentType: String,
    messageType: Number,
    messageId: Number,
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    shouldShowInput() {
      return this.contentType === 'input_email' && this.messageType === 3;
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-bubble {
  &.agent {
    background: $color-white;
    border-bottom-left-radius: $space-smaller;
    color: $color-body;
  }
}
</style>
