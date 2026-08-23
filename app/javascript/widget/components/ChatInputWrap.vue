<script>
import { defineAsyncComponent } from 'vue';
import { mapGetters } from 'vuex';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import { useAttachments } from '../composables/useAttachments';
import { useVoiceRecorder } from '../composables/useVoiceRecorder';
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
    const voiceRecorder = useVoiceRecorder();
    return {
      canHandleAttachments,
      shouldShowEmojiPicker,
      hasEmojiPickerEnabled,
      voiceRecorder,
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
      return (
        this.canHandleAttachments &&
        this.userInput.length === 0 &&
        !this.voiceRecorder.isRecording.value
      );
    },
    showMicButton() {
      return (
        this.userInput.length === 0 && !this.voiceRecorder.isRecording.value
      );
    },
    showSendButton() {
      return this.userInput.length > 0;
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
      if (this.$refs.chatInput) {
        this.$refs.chatInput.focus();
      }
    },
    async handleVoiceRecord() {
      const { isRecording, audioBlob } = this.voiceRecorder;
      if (isRecording.value) {
        this.voiceRecorder.stopRecording();
        // Wait a tick for onstop to fire and set audioBlob
        await this.$nextTick();
        if (this.voiceRecorder.audioBlob.value) {
          this.sendVoiceNote(this.voiceRecorder.audioBlob.value);
        }
      } else {
        this.voiceRecorder.startRecording();
      }
    },
    cancelVoiceRecording() {
      this.voiceRecorder.cancelRecording();
    },
    sendVoiceNote(blob) {
      const file = new File([blob], `voice-note-${Date.now()}.webm`, {
        type: 'audio/webm',
      });
      this.onSendAttachment({
        file,
        thumbUrl: '',
        fileType: 'audio',
      });
    },
  },
};
</script>

<template>
  <div
    v-if="!voiceRecorder.isRecording.value"
    class="items-center flex ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-[7px] transition-all duration-200 bg-n-background !shadow-[0_0_0_1px,0_0_2px_3px]"
    :class="{
      '!shadow-[var(--widget-color,#12b892)]': isFocused,
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
    <div class="relative flex items-center ltr:pl-2 rtl:pr-2">
      <ChatAttachmentButton
        v-if="showAttachment"
        class="text-n-slate-12"
        :on-attach="onSendAttachment"
      />
      <button
        v-if="showMicButton"
        class="flex items-center justify-center min-h-8 min-w-8"
        aria-label="Record voice note"
        @click="handleVoiceRecord"
      >
        <FluentIcon icon="microphone-outline" class="text-n-slate-12" />
      </button>
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
  <!-- [whisker] Voice recording UI -->
  <div
    v-else
    class="items-center flex gap-2 ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-[7px] bg-n-background !shadow-n-strong"
  >
    <button
      class="flex items-center justify-center min-h-8 min-w-8 rounded-full bg-n-ruby-9 text-white"
      aria-label="Cancel recording"
      @click="cancelVoiceRecording"
    >
      <FluentIcon icon="close" />
    </button>
    <div class="flex items-center gap-2 flex-1">
      <span class="w-2 h-2 rounded-full bg-n-ruby-9 animate-pulse" />
      <span class="text-sm text-n-slate-12 tabular-nums">
        {{ voiceRecorder.formatDuration(voiceRecorder.duration.value) }}
      </span>
    </div>
    <button
      class="flex items-center justify-center min-h-10 min-w-10 rounded-full bg-n-brand text-white"
      aria-label="Send voice note"
      @click="handleVoiceRecord"
    >
      <FluentIcon icon="send" />
    </button>
  </div>
</template>

<style scoped lang="scss">
.user-message-input {
  @apply border-none outline-none w-full placeholder:text-n-slate-10 resize-none h-8 min-h-8 max-h-60 py-1 px-0 my-2 bg-n-background text-n-slate-12 transition-all duration-200;
}
</style>
