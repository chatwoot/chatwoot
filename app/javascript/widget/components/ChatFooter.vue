<template>
  <footer class="footer">
    <chat-input-wrap
      :on-send-message="handleSendMessage"
      :on-send-attachment="handleSendAttachment"
      :conversation-id="conversationId"
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
    conversationId: {
      type: Number,
      default: 0,
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage', 'sendAttachment']),
    handleSendMessage(content) {
      this.sendMessage({
        content,
        conversationId: this.conversationId,
      });
    },
    handleSendAttachment(attachment) {
      this.sendAttachment({ attachment, conversationId: this.conversationId });
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
