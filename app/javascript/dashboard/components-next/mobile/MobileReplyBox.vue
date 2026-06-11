<script setup>
import {
  ref,
  computed,
  nextTick,
  watch,
  onMounted,
  onBeforeUnmount,
} from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { DirectUpload } from 'activestorage';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { vHapticTap } from './hapticTap';
import WhatsappTemplates from 'dashboard/components/widgets/conversation/WhatsappTemplates/Modal.vue';
import AudioRecorder from 'dashboard/components/widgets/WootWriter/AudioRecorder.vue';

const store = useStore();
const { t } = useI18n();
const { success } = useHaptics();

const message = ref('');
const isPrivate = ref(false);
const isFocused = ref(false);
const attachedFiles = ref([]);
const fileInput = ref(null);
const textareaRef = ref(null);

// Audio recorder state
const isRecordingAudio = ref(false);
const recordingAudioState = ref('');
const hasRecordedAudio = ref(false);
const recordingAudioDurationText = ref('00:00');
const audioRecorderRef = ref(null);

const showWhatsAppTemplatesModal = ref(false);

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const inboxData = computed(() => {
  const inboxId = currentChat.value?.inbox_id;
  if (!inboxId) return {};
  return store.getters['inboxes/getInbox'](inboxId) || {};
});

const channelType = computed(() => {
  return (
    inboxData.value?.channel_type || currentChat.value?.meta?.channel || ''
  );
});

// Match desktop ReplyBox behavior: can_reply false + non-WhatsApp/API = forced private
const isReplyAllowed = computed(() => {
  const chat = currentChat.value;
  if (!chat) return true;
  if (chat.can_reply) return true;
  // WhatsApp/API/Twilio can always reply even when can_reply is false
  const channel = channelType.value;
  return (
    channel === 'Channel::Whatsapp' ||
    channel === 'Channel::Api' ||
    channel === 'Channel::TwilioSms'
  );
});

const effectivePrivate = computed(() => {
  if (!isReplyAllowed.value) return true;
  return isPrivate.value;
});

// WhatsApp/API: can_reply false + not private = editor disabled (only templates allowed)
const isEditorDisabled = computed(() => {
  return (
    isReplyAllowed.value &&
    !currentChat.value?.can_reply &&
    !effectivePrivate.value
  );
});

const hasWhatsAppTemplates = computed(() => {
  const inboxId = currentChat.value?.inbox_id;
  if (!inboxId) return false;
  const templates = store.getters['inboxes/getWhatsAppTemplates'](inboxId);
  return !!(templates && templates.length);
});

const placeholder = computed(() => {
  if (isEditorDisabled.value) {
    return t('MOBILE.CHAT.USE_TEMPLATE');
  }
  if (effectivePrivate.value) {
    return t('MOBILE.CHAT.PRIVATE_PLACEHOLDER');
  }
  return t('MOBILE.CHAT.TYPE_MESSAGE');
});

const hasContent = computed(() => {
  return message.value.trim().length > 0 || attachedFiles.value.length > 0;
});

// Show audio recorder if not in private note mode and not editor disabled
const showAudioRecorder = computed(() => {
  return !effectivePrivate.value && !isEditorDisabled.value;
});

// Show the recorder UI when actively recording
const showAudioRecorderEditor = computed(() => {
  return showAudioRecorder.value && isRecordingAudio.value;
});

// Audio format: WhatsApp/API get MP3, others get WAV
const audioRecordFormat = computed(() => {
  const ch = channelType.value;
  if (
    ch === 'Channel::Whatsapp' ||
    ch === 'Channel::TwilioSms' ||
    ch === 'Channel::Api'
  ) {
    return AUDIO_FORMATS.MP3;
  }
  return AUDIO_FORMATS.WAV;
});

const sender = computed(() => ({
  name: currentUser.value?.name,
  thumbnail: currentUser.value?.avatar_url,
}));

const resizeTextarea = () => {
  nextTick(() => {
    const el = textareaRef.value;
    if (!el) return;
    el.style.height = '20px';
    const maxHeight = 120; // ~5 lines
    const newHeight = Math.min(el.scrollHeight, maxHeight);
    el.style.height = `${newHeight}px`;
    el.style.overflowY = newHeight >= maxHeight ? 'auto' : 'hidden';
  });
};

watch(message, resizeTextarea);

const togglePrivate = () => {
  if (!isReplyAllowed.value) return;
  isPrivate.value = !isPrivate.value;
  attachedFiles.value = [];
};

const resetAudioRecorder = () => {
  recordingAudioDurationText.value = '00:00';
  isRecordingAudio.value = false;
  recordingAudioState.value = '';
  hasRecordedAudio.value = false;
  // Remove any previously recorded audio from attachments
  attachedFiles.value = attachedFiles.value.filter(f => !f?.isRecordedAudio);
};

const onSend = async () => {
  if (isEditorDisabled.value) return;
  const text = message.value.trim();
  if (!text && !attachedFiles.value.length) return;

  const messagePayload = {
    conversationId: currentChat.value.id,
    message: text,
    private: effectivePrivate.value,
    sender: sender.value,
  };

  if (attachedFiles.value.length) {
    messagePayload.files = attachedFiles.value.map(f =>
      f.blobSignedId ? f.blobSignedId : f.resource.file
    );
  }

  // Haptic fires at tap time: iOS drops the Taptic switch trick once the
  // user activation expires across an await.
  success();
  try {
    await store.dispatch('createPendingMessageAndSend', messagePayload);
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
    message.value = '';
    attachedFiles.value = [];
    // Reset audio state after sending
    resetAudioRecorder();
    nextTick(resizeTextarea);
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error || t('CONVERSATION.MESSAGE_ERROR');
    useAlert(errorMessage);
  }
};

const onKeydown = e => {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    onSend();
  }
};

// --- Audio recorder methods ---

const toggleAudioRecorder = () => {
  isRecordingAudio.value = !isRecordingAudio.value;
  if (!isRecordingAudio.value) {
    resetAudioRecorder();
  }
};

const onRecordProgressChanged = duration => {
  recordingAudioDurationText.value = duration;
};

const onFinishRecorder = payload => {
  recordingAudioState.value = 'stopped';
  hasRecordedAudio.value = true;
  if (!payload?.file) return;

  // payload = { name, type, size, file } where `file` is a File object
  const audioFile = payload.file;

  attachedFiles.value.push({
    currentChatId: currentChat.value.id,
    resource: { file: audioFile },
    isPrivate: effectivePrivate.value,
    thumb: URL.createObjectURL(audioFile),
    isRecordedAudio: true,
  });
};

const toggleAudioRecorderPlayPause = () => {
  if (!audioRecorderRef.value) return;
  if (!recordingAudioState.value) {
    audioRecorderRef.value.stopRecording();
  } else {
    audioRecorderRef.value.playPause();
  }
};

// --- File attachment methods ---

const onAttachClick = () => {
  fileInput.value?.click();
};

const onFileChange = async e => {
  const files = Array.from(e.target.files);
  if (!files.length) return;

  files.forEach(file => {
    const maxSize = 40; // MB
    if (!checkFileSizeLimit(file, maxSize)) {
      useAlert(
        t('CONVERSATION.FILE_SIZE_LIMIT', {
          MAXIMUM_SUPPORTED_FILE_UPLOAD_SIZE: maxSize,
        })
      );
      return;
    }

    if (globalConfig.value?.directUploadsEnabled) {
      const upload = new DirectUpload(
        file,
        `/rails/active_storage/direct_uploads`
      );
      upload.create((error, blob) => {
        if (error) {
          useAlert(t('CONVERSATION.FILE_UPLOAD_ERROR'));
        } else {
          const reader = new FileReader();
          reader.readAsDataURL(file);
          reader.onloadend = () => {
            attachedFiles.value.push({
              currentChatId: currentChat.value.id,
              resource: blob,
              isPrivate: effectivePrivate.value,
              thumb: reader.result,
              blobSignedId: blob.signed_id,
            });
          };
        }
      });
    } else {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onloadend = () => {
        attachedFiles.value.push({
          currentChatId: currentChat.value.id,
          resource: { file },
          isPrivate: effectivePrivate.value,
          thumb: reader.result,
        });
      };
    }
  });

  e.target.value = '';
};

const removeAttachment = index => {
  attachedFiles.value.splice(index, 1);
};

const onTyping = () => {
  store.dispatch('conversationTypingStatus/toggleTyping', {
    status: 'on',
    conversationId: currentChat.value.id,
    isPrivate: effectivePrivate.value,
  });
};

const onTypingOff = () => {
  store.dispatch('conversationTypingStatus/toggleTyping', {
    status: 'off',
    conversationId: currentChat.value.id,
    isPrivate: effectivePrivate.value,
  });
};

const onInputBlur = () => {
  isFocused.value = false;
  onTypingOff();
};

const openWhatsappTemplateModal = () => {
  showWhatsAppTemplatesModal.value = true;
};

const onSendWhatsAppReply = async messagePayload => {
  success();
  try {
    await store.dispatch('createPendingMessageAndSend', {
      conversationId: currentChat.value.id,
      ...messagePayload,
    });
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
    showWhatsAppTemplatesModal.value = false;
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error || t('CONVERSATION.MESSAGE_ERROR');
    useAlert(errorMessage);
  }
};

const focusReplyTextarea = (payload = {}) => {
  if (isEditorDisabled.value) return;
  const conversationId = payload?.conversationId;
  if (conversationId && currentChat.value?.id !== conversationId) return;

  const prefill = typeof payload?.prefill === 'string' ? payload.prefill : '';
  if (prefill) {
    message.value = prefill;
  }

  nextTick(() => {
    const el = textareaRef.value;
    if (!el) return;
    el.focus({ preventScroll: false });
    try {
      const len = el.value?.length || 0;
      el.setSelectionRange(len, len);
    } catch (e) {
      // setSelectionRange not supported on every textarea; safe to ignore.
    }
    resizeTextarea();
  });
};

onMounted(() => {
  emitter.on(BUS_EVENTS.FOCUS_REPLY_BOX, focusReplyTextarea);
});

onBeforeUnmount(() => {
  emitter.off(BUS_EVENTS.FOCUS_REPLY_BOX, focusReplyTextarea);
});
</script>

<template>
  <div class="flex flex-col border-t border-n-weak bg-n-background">
    <!-- Attachment preview -->
    <div
      v-if="attachedFiles.length"
      class="flex gap-2 px-3 pt-2 overflow-x-auto"
    >
      <div
        v-for="(file, index) in attachedFiles"
        :key="index"
        class="relative flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden border border-n-weak"
      >
        <img :src="file.thumb" class="w-full h-full object-cover" alt="" />
        <button
          class="absolute -top-1 -right-1 w-5 h-5 bg-n-slate-12 text-n-slate-1 rounded-full flex items-center justify-center text-xs"
          :aria-label="t('CONVERSATION.REPLYBOX.REMOVE_ATTACHMENT')"
          @click="removeAttachment(index)"
        >
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    </div>

    <!-- Audio recorder UI (visible when recording) -->
    <div v-if="showAudioRecorderEditor" class="px-3 pt-2">
      <AudioRecorder
        ref="audioRecorderRef"
        :audio-record-format="audioRecordFormat"
        @recorder-progress-changed="onRecordProgressChanged"
        @finish-record="onFinishRecorder"
        @play="recordingAudioState = 'playing'"
        @pause="recordingAudioState = 'paused'"
      />
    </div>

    <!-- Input row -->
    <div class="flex items-end gap-1.5 px-2 py-2">
      <!-- WhatsApp template button (when editor disabled) -->
      <button
        v-if="isEditorDisabled && hasWhatsAppTemplates"
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 text-green-600 hover:text-green-700 mb-0.5"
        @click="openWhatsappTemplateModal"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <path
            d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"
          />
        </svg>
      </button>
      <!-- Attach button (normal mode) -->
      <button
        v-else-if="!showAudioRecorderEditor"
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 text-n-slate-11 hover:text-n-slate-12 mb-0.5"
        :class="{ 'opacity-50 pointer-events-none': isEditorDisabled }"
        :disabled="isEditorDisabled"
        @click="onAttachClick"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <line x1="12" y1="5" x2="12" y2="19" />
          <line x1="5" y1="12" x2="19" y2="12" />
        </svg>
      </button>
      <!-- Cancel recording button (shown when recorder is open) -->
      <button
        v-else
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 text-n-red-9 hover:text-n-red-11 mb-0.5"
        @click="toggleAudioRecorder"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>
      <input
        ref="fileInput"
        type="file"
        multiple
        class="hidden"
        @change="onFileChange"
      />

      <!-- Text input area (hidden when recording) -->
      <div
        v-if="!showAudioRecorderEditor"
        class="mobile-reply-input flex-1 flex items-center rounded-2xl border px-3 py-1.5 transition-colors min-h-[36px]"
        :class="[
          effectivePrivate
            ? 'bg-n-amber-2 border-n-amber-5'
            : 'bg-n-alpha-2 border-n-weak',
          isFocused && !effectivePrivate ? 'border-n-brand' : '',
        ]"
      >
        <textarea
          ref="textareaRef"
          v-model="message"
          :placeholder="placeholder"
          :disabled="isEditorDisabled"
          rows="1"
          class="mobile-reply-textarea flex-1 min-w-0 w-full bg-transparent text-sm text-n-slate-12 placeholder:text-n-slate-9 placeholder:text-xs resize-none outline-none max-h-[120px] h-5 leading-5 overflow-y-hidden"
          :class="{ 'opacity-50 cursor-not-allowed': isEditorDisabled }"
          @keydown="onKeydown"
          @input="onTyping"
          @blur="onInputBlur"
          @focus="isFocused = true"
        />

        <!-- Lock toggle -->
        <button
          class="flex items-center justify-center w-7 h-7 flex-shrink-0 ml-1 transition-colors"
          :class="effectivePrivate ? 'text-n-amber-11' : 'text-n-slate-9'"
          :disabled="!isReplyAllowed"
          @click="togglePrivate"
        >
          <!-- Locked (private note) -->
          <svg
            v-if="effectivePrivate"
            xmlns="http://www.w3.org/2000/svg"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          <!-- Unlocked (reply) -->
          <svg
            v-else
            xmlns="http://www.w3.org/2000/svg"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
            <path d="M7 11V7a5 5 0 0 1 9.9-1" />
          </svg>
        </button>
      </div>
      <!-- Audio recorder duration display -->
      <div v-else class="flex-1 flex items-center justify-center min-h-[36px]">
        <span class="text-sm font-mono text-n-slate-11">{{
          recordingAudioDurationText
        }}</span>
      </div>

      <!-- Send button (when has content, including recorded audio) -->
      <button
        v-if="hasContent && !isEditorDisabled"
        v-haptic-tap
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 rounded-full mb-0.5 transition-colors"
        :class="
          effectivePrivate
            ? 'bg-n-amber-9 text-white'
            : 'bg-n-slate-12 text-n-slate-1'
        "
        @click="onSend"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2.5"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <line x1="12" y1="19" x2="12" y2="5" />
          <polyline points="5 12 12 5 19 12" />
        </svg>
      </button>
      <!-- Play/Stop button (when recording is in progress, before audio is ready) -->
      <button
        v-else-if="showAudioRecorderEditor && !hasRecordedAudio"
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 rounded-full mb-0.5 bg-n-red-9 text-white transition-colors"
        @click="toggleAudioRecorderPlayPause"
      >
        <!-- Stop icon -->
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="currentColor"
        >
          <rect x="4" y="4" width="16" height="16" rx="2" />
        </svg>
      </button>
      <!-- Mic button (idle state, no content) -->
      <button
        v-else-if="showAudioRecorder && !isEditorDisabled"
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 text-n-slate-11 mb-0.5"
        @click="toggleAudioRecorder"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
          <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
          <line x1="12" y1="19" x2="12" y2="23" />
          <line x1="8" y1="23" x2="16" y2="23" />
        </svg>
      </button>
      <!-- Mic button placeholder (disabled states) -->
      <button
        v-else
        class="flex items-center justify-center w-9 h-9 flex-shrink-0 text-n-slate-11 mb-0.5 opacity-40"
        disabled
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
          <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
          <line x1="12" y1="19" x2="12" y2="23" />
          <line x1="8" y1="23" x2="16" y2="23" />
        </svg>
      </button>
    </div>

    <WhatsappTemplates
      :inbox-id="currentChat?.inbox_id"
      :conversation-id="currentChat?.id"
      :show="showWhatsAppTemplatesModal"
      @on-send="onSendWhatsAppReply"
      @cancel="showWhatsAppTemplatesModal = false"
      @close="showWhatsAppTemplatesModal = false"
    />
  </div>
</template>

<style scoped>
.mobile-reply-textarea {
  -webkit-appearance: none;
  appearance: none;
  border: 0 !important;
  outline: none !important;
  box-shadow: none !important;
  -webkit-tap-highlight-color: transparent;
  font-family: inherit;
}

.mobile-reply-textarea:focus,
.mobile-reply-textarea:focus-visible,
.mobile-reply-textarea:focus-within {
  outline: none !important;
  box-shadow: none !important;
  border: 0 !important;
}
</style>
