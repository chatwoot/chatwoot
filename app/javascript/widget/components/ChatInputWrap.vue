<script>
import { mapGetters } from 'vuex';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import { useAttachments } from '../composables/useAttachments';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';

import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { isStandaloneMode } from 'widget/helpers/urlParamsHelper';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    EmojiInput,
    FluentIcon,
    ResizableTextArea,
  },
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
  setup() {
    const {
      canHandleAttachments,
      shouldShowEmojiPicker,
      hasEmojiPickerEnabled,
    } = useAttachments();
    return {
      canHandleAttachments,
      shouldShowEmojiPicker,
      hasEmojiPickerEnabled,
    };
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
      shouldShowEmojiPicker: 'appConfig/getShouldShowEmojiPicker',
    }),
    showAttachment() {
      return this.canHandleAttachments;
    },
    showSendButton() {
      return this.isStandaloneChat || this.userInput.length > 0;
    },
    isStandaloneChat() {
      return isStandaloneMode(window.location.search);
    },
    maxMessageLength() {
      return 5000;
    },
    characterCount() {
      return `${this.userInput.length}/${this.maxMessageLength}`;
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
      const content = this.userInput.trim();
      if (content && content.length <= this.maxMessageLength) {
        this.onSendMessage(content);
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
  <div
    class="flex flex-col rounded-[7px] transition-all duration-200 bg-n-background px-3 py-2 !shadow-[0_0_0_1px,0_0_2px_3px]"
    :class="{
      '!shadow-[var(--widget-color,#2781f6)]': isFocused,
      '!shadow-n-strong dark:!shadow-n-strong': !isFocused,
    }"
    @keydown.esc="hideEmojiPicker"
  >
    <div class="flex items-center justify-between min-h-8">
      <div class="flex items-center">
        <button
          v-if="shouldShowEmojiPicker && hasEmojiPickerEnabled"
          class="flex items-center justify-center min-h-8 min-w-8"
          :aria-label="$t('EMOJI.ARIA_LABEL')"
          @click="toggleEmojiPicker"
        >
          <FluentIcon
            icon="emoji"
            class="transition-all duration-150"
            :class="{
              'text-n-slate-12': !showEmojiPicker,
              'text-n-brand': showEmojiPicker,
            }"
          />
        </button>
        <EmojiInput
          v-if="shouldShowEmojiPicker && showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          :on-click="emojiOnClick"
          @keydown.esc="hideEmojiPicker"
        />
        <ChatAttachmentButton
          v-if="showAttachment"
          class="text-n-slate-12"
          :on-attach="onSendAttachment"
          icon="document"
          accept="image/*"
          :enable-paste="false"
        />
        <ChatAttachmentButton
          v-if="showAttachment"
          class="text-n-slate-12"
          :on-attach="onSendAttachment"
          icon="video-add"
          accept="video/*"
          :enable-paste="false"
        />
        <ChatAttachmentButton
          v-if="showAttachment"
          class="text-n-slate-12"
          :on-attach="onSendAttachment"
        />
      </div>
      <span class="text-xs text-n-slate-11">
        {{ characterCount }}
      </span>
    </div>
    <div class="flex items-end gap-2">
      <ResizableTextArea
        id="chat-input"
        ref="chatInput"
        v-model="userInput"
        :rows="1"
        :maxlength="maxMessageLength"
        :aria-label="$t('CHAT_PLACEHOLDER')"
        :placeholder="$t('CHAT_PLACEHOLDER')"
        class="user-message-input reset-base"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
      />
      <ChatSendButton
        v-if="showSendButton"
        :disabled="!userInput.trim()"
        :color="widgetColor"
        @click="handleButtonClick"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.emoji-dialog {
  @apply max-w-full ltr:right-5 rtl:right-[unset] rtl:left-5 -top-[302px] before:ltr:right-2.5 before:rtl:right-[unset] before:rtl:left-2.5;
}

.user-message-input {
  @apply border-none outline-none w-full placeholder:text-n-slate-10 resize-none h-8 min-h-8 max-h-60 py-1 px-0 my-2 bg-n-background text-n-slate-12 transition-all duration-200;
}
</style>
