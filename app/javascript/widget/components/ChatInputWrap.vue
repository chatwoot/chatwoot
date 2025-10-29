<script>
import { mapGetters } from 'vuex';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import configMixin from '../mixins/configMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import darkModeMixin from '../mixins/darkModeMixin';

import EmojiInput from 'shared/components/emoji/EmojiInput.vue';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    EmojiInput,
    FluentIcon,
    ResizableTextArea,
  },
  mixins: [configMixin, darkModeMixin],
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
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
      shouldShowFilePicker: 'appConfig/getShouldShowFilePicker',
      shouldShowEmojiPicker: 'appConfig/getShouldShowEmojiPicker',
    }),
    showAttachment() {
      return (
        this.shouldShowFilePicker &&
        this.hasAttachmentsEnabled &&
        this.userInput.length === 0
      );
    },
    showSendButton() {
      return this.userInput.length > 0;
    },
    emojiIconColor() {
      return this.showEmojiPicker
        ? `text-woot-500 ${this.dm('text-black-900', 'dark:text-slate-100')}`
        : `${this.dm('text-black-900', 'dark:text-slate-100')}`;
    },
    containerClass() {
      let containerClass = `${this.dm('bg-white ', 'dark:bg-slate-600')}`;
      if (this.isFocused) containerClass += ' is-focused';
      return containerClass;
    },
  },
  watch: {
    isWidgetOpen(isWidgetOpen) {
      if (isWidgetOpen) {
        this.focusInput();
      }
    },
  },
  unmounted() {
    document.removeEventListener('keypress', this.handleEnterKeyPress);
  },
  mounted() {
    document.addEventListener('keypress', this.handleEnterKeyPress);
    if (this.isWidgetOpen) {
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

<template>
  <div class="chat-input-container">
    <div
      class="chat-message--input shadow-sm"
      :class="containerClass"
      @keydown.esc="hideEmojiPicker"
    >
      <ResizableTextArea
        id="chat-input"
        ref="chatInput"
        v-model="userInput"
        :rows="1"
        :aria-label="$t('CHAT_PLACEHOLDER')"
        :placeholder="$t('CHAT_PLACEHOLDER')"
        class="user-message-input reset-base"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
      />
      <div class="flex items-center ltr:pl-2 rtl:pr-2">
        <ChatAttachmentButton
          v-if="showAttachment"
          class="text-n-slate-12"
          :on-attach="onSendAttachment"
        />
        <button
          v-if="shouldShowEmojiPicker && hasEmojiPickerEnabled"
          class="flex items-center justify-center min-h-8 min-w-8"
          :aria-label="$t('EMOJI.ARIA_LABEL')"
          @click="toggleEmojiPicker"
        >
          <FluentIcon icon="emoji" :class="emojiIconColor" />
        </button>
        <EmojiInput
          v-if="shouldShowEmojiPicker && showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          :on-click="emojiOnClick"
          @keydown.esc="hideEmojiPicker"
        />
      </div>
    </div>
    <ChatSendButton
      v-if="showSendButton"
      :color="widgetColor"
      @click="handleButtonClick"
    />
  </div>
</template>

<style scoped lang="scss">
@import 'widget/assets/scss/variables';
@import 'widget/assets/scss/mixins';

.chat-input-container {
  display: flex;
  align-items: flex-end;
  gap: $space-small;
}

.chat-message--input {
  align-items: flex-end;
  display: flex;
  padding: 0 $space-small 0 $space-slab;
  border-radius: 7px;
  flex: 1;

  &.is-focused {
    box-shadow:
      0 0 0 1px $color-woot,
      0 0 2px 3px $color-primary-light;
  }
}

.emoji-dialog {
  @apply max-w-full ltr:right-5 rtl:right-[unset] rtl:left-5 -top-[302px] before:ltr:right-2.5 before:rtl:right-[unset] before:rtl:left-2.5;
}

.button-wrap {
  display: flex;
  align-items: center;
  padding-left: $space-small;
  margin: auto 0 $space-small;
}

.user-message-input {
  @apply border-none outline-none w-full placeholder:text-n-slate-10 resize-none h-8 min-h-8 max-h-60 py-1 px-0 my-2 bg-n-background text-n-slate-12 transition-all duration-200;
}
</style>
