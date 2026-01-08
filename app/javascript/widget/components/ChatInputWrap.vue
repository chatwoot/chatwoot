<script>
import { mapGetters } from 'vuex';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import { useAttachments } from '../composables/useAttachments';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatSendButton,
    ResizableTextArea,
  },
  mixins: [configMixin, routerMixin],
  props: {
    onSendMessage: {
      type: Function,
      default: () => {},
    },
  },
  setup() {
    const { canHandleAttachments, hasEmojiPickerEnabled } = useAttachments();
    return {
      canHandleAttachments,
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
    }),
    showSendButton() {
      return this.userInput.length > 0;
    },
    showTextUsButton() {
      return this.userInput.length === 0;
    },
    textUsButtonStyle() {
      return {
        backgroundColor: this.widgetColor,
        color: '#ffffff',
      };
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
    handleTextUsClick() {
      // Navigate to SMS form
      this.replaceRoute('sms-form');
    },
  },
};
</script>

<template>
  <div
    class="items-center flex ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-[7px] transition-all duration-200 bg-n-background !shadow-[0_0_0_1px,0_0_2px_3px]"
    :class="{
      '!shadow-n-brand dark:!shadow-n-brand': isFocused,
      '!shadow-n-strong dark:!shadow-n-strong': !isFocused,
    }"
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
      <!-- <ChatAttachmentButton
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
        <FluentIcon
          icon="emoji"
          class="transition-all duration-150"
          :class="{
            'text-n-slate-12': !showEmojiPicker,
            'text-n-brand': showEmojiPicker,
          }"
        />
      </button> -->
      <!-- <EmojiInput
        v-if="shouldShowEmojiPicker && showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :on-click="emojiOnClick"
        @keydown.esc="hideEmojiPicker"
      /> -->
      <ChatSendButton
        v-if="showSendButton"
        :color="widgetColor"
        @click="handleButtonClick"
      />
      <button
        v-if="showTextUsButton"
        type="button"
        class="min-h-8 px-4 flex items-center justify-center ml-1 rounded-xl font-medium text-sm cursor-pointer border-none flex-shrink-0 transition-opacity duration-200"
        :style="textUsButtonStyle"
        :aria-label="$t('SMS_FORM.BUTTON_TEXT')"
        @click="handleTextUsClick"
      >
        {{ $t('SMS_FORM.BUTTON_TEXT') }}
      </button>
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
