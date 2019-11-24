<template>
  <div class="chat-bubble user" v-html="formatMessage(message)"></div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  name: 'UserMessageBubble',
  mixins: [messageFormatterMixin],
  props: {
    message: String,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
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
  max-width: 80%;
  padding: $space-small $space-two;
  text-align: left;

  a {
    color: $color-white;
  }

  &.user {
    border-bottom-right-radius: $space-smaller;
  }
}
</style>
