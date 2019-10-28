<template>
  <div class="chat-bubble user">
    {{ message }}
  </div>
</template>

<script>
export default {
  name: 'UserMessageBubble',
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
  border-radius: $space-two;
  padding: $space-small $space-two;
  font-size: $font-size-default;
  background: $color-woot;
  color: $color-white;
  display: inline-block;
  max-width: 80%;
  line-height: 1.5;
  @include lightShadow;

  &.user {
    border-bottom-right-radius: $space-smaller;
  }
}
</style>
