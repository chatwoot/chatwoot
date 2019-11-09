<template>
  <div class="chat-message--input">
    <ChatInputArea v-model="userInput" :placeholder="placeholder" />
    <ChatSendButton
      :on-click="handleButtonClick"
      :disabled="!userInput.length"
    />
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
  destroyed() {
    document.removeEventListener('keypress', this.handleEnterKeyPress);
  },
  mounted() {
    document.addEventListener('keypress', this.handleEnterKeyPress);
  },

  methods: {
    handleButtonClick() {
      if (this.userInput && this.userInput.trim()) {
        this.onSendMessage(this.userInput);
      }
      this.userInput = '';
    },
    handleEnterKeyPress(e) {
      if (e.keyCode === 13 && !e.shiftKey) {
        e.preventDefault();
        this.handleButtonClick();
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-message--input {
  align-items: center;
  border-bottom: 1px $color-border-light solid;
  display: flex;
}
</style>
