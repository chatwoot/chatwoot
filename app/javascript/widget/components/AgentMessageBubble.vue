<template>
  <div class="chat-bubble agent">
    {{ message }}
  </div>
</template>

<script>
export default {
  name: 'AgentMessageBubble',
  props: {
    message: String,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
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
