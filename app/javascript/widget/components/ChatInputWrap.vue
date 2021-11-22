<template>
  <div
    class="chat-message--input"
    :class="{ 'is-focused': isFocused }"
    @keydown.esc="hideEmojiPicker"
  >
    <resizable-text-area
      id="chat-input"
      ref="chatInput"
      v-model="userInput"
      :aria-label="$t('CHAT_PLACEHOLDER')"
      :placeholder="$t('CHAT_PLACEHOLDER')"
      class="form-input user-message-input"
      @typing-off="onTypingOff"
      @typing-on="onTypingOn"
      @focus="onFocus"
      @blur="onBlur"
    />
    <div class="button-wrap">
      <chat-attachment-button
        v-if="showAttachment"
        :on-attach="onSendAttachment"
      />
      <button
        v-if="hasEmojiPickerEnabled"
        class="icon-button flex justify-center items-center"
        aria-label="Emoji picker"
        @click="toggleEmojiPicker"
      >
        <fluent-icon
          icon="emoji"
          :class="{ 'text-woot-500': showEmojiPicker }"
        />
      </button>
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :on-click="emojiOnClick"
        @keydown.esc="hideEmojiPicker"
      />
      <chat-send-button
        v-if="showSendButton"
        :on-click="handleButtonClick"
        :color="widgetColor"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import configMixin from '../mixins/configMixin';
import EmojiInput from 'shared/components/emoji/EmojiInput';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    EmojiInput,
    FluentIcon,
    ResizableTextArea,
  },
  mixins: [clickaway, configMixin],
  props: {
    onSendMessage: {
      type: Function,
      default: () => {},
    },
    onSendAttachment: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      userInput: '',
      showEmojiPicker: false,
      isFocused: false,
    };
  },

  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    showAttachment() {
      return this.hasAttachmentsEnabled && this.userInput.length === 0;
    },
    showSendButton() {
      return this.userInput.length > 0;
    },
    isOpen() {
      return this.$store.state.events.isOpen;
    },
  },
  watch: {
    isOpen(isOpen) {
      if (isOpen) {
        this.focusInput();
      }
    },
  },
  destroyed() {
    document.removeEventListener('keypress', this.handleEnterKeyPress);
  },
  mounted() {
    document.addEventListener('keypress', this.handleEnterKeyPress);
    if (this.isOpen) {
      this.focusInput();
    }
  },

  methods: {
    onBlur() {
      this.isFocused = false;
    },
    onFocus() {
      this.isFocused = true;
    },
    handleButtonClick() {
      if (this.userInput && this.userInput.trim()) {
        this.onSendMessage(this.userInput);
      }
      this.userInput = '';
      this.focusInput();
    },
    handleEnterKeyPress(e) {
      if (e.keyCode === 13 && !e.shiftKey) {
        e.preventDefault();
        this.handleButtonClick();
      }
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    hideEmojiPicker(e) {
      if (this.showEmojiPicker) {
        e.stopPropagation();
        this.toggleEmojiPicker();
      }
    },
    emojiOnClick(emoji) {
      this.userInput = `${this.userInput}${emoji} `;
    },
    onTypingOff() {
      this.toggleTyping('off');
    },
    onTypingOn() {
      this.toggleTyping('on');
    },
    toggleTyping(typingStatus) {
      this.$store.dispatch('conversation/toggleUserTyping', { typingStatus });
    },
    focusInput() {
      this.$refs.chatInput.focus();
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.chat-message--input {
  align-items: center;
  display: flex;
  padding: 0 $space-small 0 $space-slab;
  border-radius: 7px;

  &.is-focused {
    box-shadow: 0 0 0 1px $color-woot, 0 0 2px 3px $color-primary-light;
  }
}

.emoji-dialog {
  right: $space-one;
}

.button-wrap {
  display: flex;
  align-items: center;
  padding-left: $space-small;
}

.user-message-input {
  border: 0;
  height: $space-large;
  min-height: $space-large;
  max-height: 2.4 * $space-mega;
  resize: none;
  padding: 0;
  padding-top: $space-small;
  margin-top: $space-small;
  margin-bottom: $space-small;
}
</style>
