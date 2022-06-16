<template>
  <div
    v-dompurify-html="formatMessage(message, false)"
    class="chat-bubble user"
    :style="{ background: widgetColor }"
  />
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  name: 'UserMessageBubble',
  mixins: [messageFormatterMixin],
  props: {
    message: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      default: '',
    },
    widgetColor: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.chat-bubble.user::v-deep pre {
  background: $color-primary-light;
  color: $color-body;
  overflow: scroll;
  padding: $space-smaller;
}
</style>
