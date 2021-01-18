<template>
  <div
    class="chat-bubble user"
    :style="{ background: widgetColor }"
    v-html="formatMessage(message, false)"
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

<style lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.chat-bubble {
  @include light-shadow;
  background: $color-woot;
  border-radius: $space-two;
  color: $color-white;
  display: inline-block;
  font-size: $font-size-default;
  line-height: 1.5;
  padding: $space-slab $space-normal $space-slab $space-normal;
  text-align: left;
  word-break: break-word;
  max-width: 100%;

  > a {
    color: $color-primary;
    word-break: break-all;
  }

  .link {
    text-decoration: underline;
  }

  &.user {
    border-bottom-right-radius: $space-smaller;

    > a {
      color: $color-white;
    }
  }
}
</style>
<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.chat-bubble.user::v-deep pre {
  background: $color-primary-light;
  color: $color-body;
  overflow: scroll;
  padding: $space-smaller;
}
</style>
