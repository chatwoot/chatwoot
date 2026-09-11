<script>
import { defineAsyncComponent } from 'vue';
import { mapGetters } from 'vuex';

import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import VoiceRecorder from 'widget/components/VoiceRecorder.vue';
import Spinner from 'shared/components/Spinner.vue';
import { useAttachments } from '../composables/useAttachments';
import { transcribeAudioAPI } from 'widget/api/conversation';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
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
    VoiceRecorder,
    Spinner,
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
      canTranscribeAudio,
    } = useAttachments();
    return {
      canHandleAttachments,
      shouldShowEmojiPicker,
      hasEmojiPickerEnabled,
      canTranscribeAudio,
    };
  },
  data() {
    return {
      userInput: '',
      showEmojiPicker: false,
      isFocused: false,
      isRecording: false,
      isTranscribing: false,
    };
  },

  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      isWidgetOpen: 'appConfig/getIsWidgetOpen',
      shouldShowEmojiPicker: 'appConfig/getShouldShowEmojiPicker',
    }),
    isIdleInput() {
      return (
        this.userInput.length === 0 && !this.isRecording && !this.isTranscribing
      );
    },
    showAttachment() {
      return this.canHandleAttachments && this.isIdleInput;
    },
    showVoiceButton() {
      return this.canTranscribeAudio && this.isIdleInput;
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
      // The textarea (and its ref) is unmounted while recording/transcribing,
      // so ignore Enter to avoid focusing a missing input.
      if (this.isRecording || this.isTranscribing) return;
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
      // The textarea ref is absent while recording/transcribing, and callers
      // like the isWidgetOpen reopen watcher may still fire, so guard the ref.
      this.$refs.chatInput?.focus();
    },
    startRecording() {
      this.isRecording = true;
    },
    onRecordCancel() {
      this.isRecording = false;
    },
    onRecordError() {
      this.isRecording = false;
      emitter.emit(BUS_EVENTS.SHOW_ALERT, {
        message: this.$t('VOICE_RECORDER.PERMISSION_ERROR'),
      });
    },
    async onRecordFinish(audioFile) {
      this.isRecording = false;
      this.isTranscribing = true;
      try {
        const { data } = await transcribeAudioAPI(audioFile);
        const transcription = (data.transcription || '').trim();
        if (transcription) {
          this.userInput = this.userInput
            ? `${this.userInput} ${transcription}`
            : transcription;
        }
        this.focusInput();
      } catch (error) {
        emitter.emit(BUS_EVENTS.SHOW_ALERT, {
          message: this.$t('VOICE_RECORDER.TRANSCRIPTION_ERROR'),
        });
      } finally {
        this.isTranscribing = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="items-center flex ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2 rounded-[7px] transition-all duration-200 bg-n-background !shadow-[0_0_0_1px,0_0_2px_3px]"
    :class="{
      '!shadow-[var(--widget-color,#2781f6)]': isFocused,
      '!shadow-n-strong dark:!shadow-n-strong': !isFocused,
    }"
    @keydown.esc="hideEmojiPicker"
  >
    <VoiceRecorder
      v-if="isRecording"
      class="flex-1 my-2"
      @finish="onRecordFinish"
      @cancel="onRecordCancel"
      @error="onRecordError"
    />
    <ResizableTextArea
      v-else
      id="chat-input"
      ref="chatInput"
      v-model="userInput"
      :rows="1"
      :aria-label="$t('CHAT_PLACEHOLDER')"
      :placeholder="
        isTranscribing
          ? $t('VOICE_RECORDER.TRANSCRIBING')
          : $t('CHAT_PLACEHOLDER')
      "
      :disabled="isTranscribing"
      class="user-message-input reset-base"
      @typing-off="onTypingOff"
      @typing-on="onTypingOn"
      @focus="onFocus"
      @blur="onBlur"
    />
    <div
      v-if="!isRecording"
      class="relative flex items-center ltr:pl-2 rtl:pr-2"
    >
      <Spinner v-if="isTranscribing" size="small" />
      <ChatAttachmentButton
        v-if="showAttachment"
        class="text-n-slate-12"
        :on-attach="onSendAttachment"
      />
      <button
        v-if="showVoiceButton"
        class="flex items-center justify-center min-h-8 min-w-8 text-n-slate-12"
        :aria-label="$t('VOICE_RECORDER.START')"
        @click="startRecording"
      >
        <FluentIcon icon="microphone" />
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
</template>

<style scoped lang="scss">
.user-message-input {
  @apply border-none outline-none w-full placeholder:text-n-slate-10 resize-none h-8 min-h-8 max-h-60 py-1 px-0 my-2 bg-n-background text-n-slate-12 transition-all duration-200;
}
</style>
