<template>
  <footer class="footer">
    <ChatInputWrap
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
    />
  </footer>
</template>

<script>
import { mapActions } from 'vuex';
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
  },
  methods: {
    ...mapActions('conversation', ['sendMessage', 'sendAttachment']),
    handleSendMessage(content) {
      this.sendMessage({
        content,
      });
    },
    handleSendAttachment(attachment) {
      this.sendAttachment({ attachment });
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.footer {
  background: $color-white;
  box-sizing: border-box;
  padding: $space-small $space-slab;
  width: 100%;
  border-radius: 7px;
  @include shadow-big;
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
