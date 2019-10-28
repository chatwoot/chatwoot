<template>
  <div class="input-wrap">
    <div>
      <ChatInputArea v-model="userInput" :placeholder="placeholder" />
    </div>
    <div class="message-button-wrap">
      <ChatSendButton
        :on-click="handleButtonClick"
        :disabled="!userInput.length"
      />
    </div>
  </div>
</template>

<script>
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import ChatInputArea from 'widget/components/ChatInputArea.vue';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatSendButton,
    ChatInputArea,
  },

  props: {
    placeholder: {
      type: String,
      default: 'Type your message',
    },
    onSendMessage: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      userInput: '',
    };
  },
  methods: {
    handleButtonClick() {
      if (this.userInput) {
        this.onSendMessage(this.userInput);
      }
      this.userInput = '';
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.input-wrap {
  .message-button-wrap {
    align-items: center;
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    margin-top: $space-small;
  }
}
</style>
