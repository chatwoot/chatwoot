<template>
  <footer class="footer">
    <ChatInputWrap :on-send-message="onSendMessage" />
  </footer>
</template>

<script>
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';

export default {
  components: {
    ChatInputWrap,
  },
  props: {
    msg: String,
    onSendMessage: Function,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.footer {
  background: $color-white;
  box-shadow: 0 -$space-micro 3px rgba(50, 50, 93, 0.04),
    0 -1px 2px rgba(0, 0, 0, 0.03);
  box-sizing: border-box;
  padding: $space-small;
  width: 100%;
}
</style>
