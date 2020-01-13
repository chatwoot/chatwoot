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
    msg: {
      type: String,
      default: '',
    },
    onSendMessage: {
      type: Function,
      default: () => {},
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.footer {
  background: $color-white;
  box-sizing: border-box;
  padding: $space-small $space-slab;
  width: 100%;
  border-radius: 7px;
  box-shadow: 0 20px 25px -10px rgba(0, 0, 0, 0.1),
    0 10px 10px -10px rgba(0, 0, 0, 0.04) !important;
}

.branding {
  align-items: center;
  color: $color-body;
  display: flex;
  font-size: $font-size-default;
  justify-content: center;
  padding: $space-one;
  text-align: center;
  text-decoration: none;

  img {
    margin-right: $space-small;
    max-width: $space-two;
  }
}
</style>
