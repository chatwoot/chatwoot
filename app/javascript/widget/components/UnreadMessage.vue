<template>
  <div class="chat-bubble-wrap">
    <div class="chat-bubble agent">
      <div class="message-content" v-html="formatMessage(message, false)"></div>
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
export default {
  name: 'AgentMessageBubble',
  components: {},
  mixins: [messageFormatterMixin],
  props: {
    message: {
      type: String,
      default: '',
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

    .link {
      word-break: break-word;
      color: $color-woot;
    }
  }
}
</style>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.chat-bubble {
  padding: $space-normal;
}
.chat-bubble .message-content::v-deep pre {
  background: $color-primary-light;
  color: $color-body;
  overflow: scroll;
  padding: $space-smaller;
}
</style>
