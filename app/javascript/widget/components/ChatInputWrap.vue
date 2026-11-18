<script>
import { defineAsyncComponent } from 'vue';
import { mapGetters } from 'vuex';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import PendingAttachments from 'widget/components/PendingAttachments.vue';
import { useAttachments } from '../composables/useAttachments';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';

const EmojiPicker = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiPicker.vue')
);

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    EmojiPicker,
    FluentIcon,
    PendingAttachments,
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
      // The inbox can hold attachments until the visitor sends them with the text.
      sendAttachmentsWithMessage:
        window.chatwootWebChannel.sendAttachmentsWithMessage,
    };
  },
  data() {
    return {
      userInput: '',
      pendingAttachments: [],
      uploadsInFlight: 0,
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
      return (
        this.canHandleAttachments &&
        (this.sendAttachmentsWithMessage || this.userInput.length === 0)
      );
    },
    showSendButton() {
      return this.userInput.length > 0 || this.pendingAttachments.length > 0;
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
      // An attachment still uploading belongs to this message; sending now would leave it out.
      if (this.sendAttachmentsWithMessage && this.uploadsInFlight) return;
      if (this.pendingAttachments.length) {
        this.sendPendingAttachments();
      } else if (this.userInput && this.userInput.trim()) {
        this.onSendMessage(this.userInput);
      }
      this.userInput = '';
      this.focusInput();
    },
    // A failed message with attachments has no retry, so the files and the text come back to
    // the composer for the visitor to send again.
    async sendPendingAttachments() {
      const attachments = this.pendingAttachments;
      const content = this.userInput.trim();
      this.pendingAttachments = [];
      const sent = await this.onSendAttachment(attachments, content);
      if (sent !== false) return;
      this.pendingAttachments = [...attachments, ...this.pendingAttachments];
      if (!this.userInput) this.userInput = content;
    },
    onAttach(attachment) {
      if (this.sendAttachmentsWithMessage) {
        this.pendingAttachments.push(attachment);
        return;
      }
      this.onSendAttachment([attachment]);
    },
    removePendingAttachment(index) {
      this.pendingAttachments.splice(index, 1);
    },
    handleEnterKeyPress(e) {
      // Enter on a button, such as a remove or capture button, activates that button.
      if (e.target.closest?.('button')) return;
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
    onSelectEmoji({ value }) {
      this.emojiOnClick(value);
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
    class="flex flex-col ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-[7px] transition-all duration-200 bg-n-background !shadow-[0_0_0_1px,0_0_2px_3px]"
    :class="{
      '!shadow-[var(--widget-color,#2781f6)]': isFocused,
      '!shadow-n-strong dark:!shadow-n-strong': !isFocused,
    }"
    @keydown.esc="hideEmojiPicker"
  >
    <PendingAttachments
      v-if="pendingAttachments.length"
      :attachments="pendingAttachments"
      @remove="removePendingAttachment"
    />
    <div class="flex items-center">
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
      <div class="relative flex items-center ltr:pl-2 rtl:pr-2">
        <ChatAttachmentButton
          v-if="showAttachment"
          class="text-n-slate-12"
          :on-attach="onAttach"
          @uploads-change="uploadsInFlight = $event"
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
        </button>
        <EmojiPicker
          v-if="shouldShowEmojiPicker && showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          class="!bottom-full end-0 mb-2 max-w-[calc(100vw-3rem)]"
          @select="onSelectEmoji"
          @keydown.esc="hideEmojiPicker"
        />
        <ChatSendButton
          v-if="showSendButton"
          :color="widgetColor"
          @click="handleButtonClick"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.user-message-input {
  @apply border-none outline-none w-full placeholder:text-n-slate-10 resize-none h-8 min-h-8 max-h-60 py-1 px-0 my-2 bg-n-background text-n-slate-12 transition-all duration-200;
}
</style>
