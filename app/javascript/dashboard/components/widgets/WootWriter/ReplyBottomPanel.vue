<script setup>
import { ref, computed, onMounted } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useMapGetter } from 'dashboard/composables/store';
import { useInbox } from 'dashboard/composables/useInbox';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import VideoCallButton from '../VideoCallButton.vue';
import AIAssistanceButton from '../AIAssistanceButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  isNote: {
    type: Boolean,
    default: false,
  },
  onSend: {
    type: Function,
    default: () => {},
  },
  sendButtonText: {
    type: String,
    default: '',
  },
  recordingAudioDurationText: {
    type: String,
    default: '00:00',
  },
  inbox: {
    type: Object,
    default: () => ({}),
  },
  showFileUpload: {
    type: Boolean,
    default: false,
  },
  showAudioRecorder: {
    type: Boolean,
    default: false,
  },
  onFileUpload: {
    type: Function,
    default: () => {},
  },
  toggleEmojiPicker: {
    type: Function,
    default: () => {},
  },
  toggleAudioRecorder: {
    type: Function,
    default: () => {},
  },
  toggleAudioRecorderPlayPause: {
    type: Function,
    default: () => {},
  },
  isRecordingAudio: {
    type: Boolean,
    default: false,
  },
  recordingAudioState: {
    type: String,
    default: '',
  },
  isSendDisabled: {
    type: Boolean,
    default: false,
  },
  isOnPrivateNote: {
    type: Boolean,
    default: false,
  },
  enableMultipleFileUpload: {
    type: Boolean,
    default: true,
  },
  enableWhatsAppTemplates: {
    type: Boolean,
    default: false,
  },
  enableContentTemplates: {
    type: Boolean,
    default: false,
  },
  conversationId: {
    type: Number,
    required: true,
  },
  message: {
    type: String,
    default: '',
  },
  newConversationModalActive: {
    type: Boolean,
    default: false,
  },
  portalSlug: {
    type: String,
    required: true,
  },
  conversationType: {
    type: String,
    default: '',
  },
  showQuotedReplyToggle: {
    type: Boolean,
    default: false,
  },
  quotedReplyEnabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'replaceText',
  'toggleInsertArticle',
  'selectWhatsappTemplate',
  'selectContentTemplate',
  'toggleQuotedReply',
]);

const { t } = useI18n();

const uploadRef = ref(false);

const { setSignatureFlagForInbox, fetchSignatureFlagFromUISettings } =
  useUISettings();

const keyboardEvents = {
  '$mod+Alt+KeyA': {
    action: () => {
      // TODO: This is really hacky, we need to replace the file picker component with
      // a custom one, where the logic and the component markup is isolated.
      // Once we have the custom component, we can remove the hacky logic below.

      const uploadTriggerButton = document.querySelector(
        '#conversationAttachment'
      );
      uploadTriggerButton.click();
    },
    allowOnFocusedInput: true,
  },
};

useKeyboardEvents(keyboardEvents);

const uiFlags = useMapGetter('integrations/getUIFlags');
const { isCloudFeatureEnabled } = useAccount();

const {
  channelType,
  isALineChannel,
  isAnInstagramChannel,
  isAWebWidgetInbox,
  isAPIInbox,
} = useInbox();

const showAttachButton = computed(() => {
  return props.showFileUpload || props.isNote;
});

const showAudioRecorderButton = computed(() => {
  if (isALineChannel.value) {
    return false;
  }
  // Disable audio recorder for safari browser as recording is not supported
  // const isSafari = /^((?!chrome|android|crios|fxios).)*safari/i.test(
  //   navigator.userAgent
  // );

  return (
    isCloudFeatureEnabled(FEATURE_FLAGS.VOICE_RECORDER) &&
    props.showAudioRecorder
    // !isSafari
  );
});

const showAudioPlayStopButton = computed(() => {
  return props.showAudioRecorder && props.isRecordingAudio;
});

const isInstagramDM = computed(() => {
  return props.conversationType === 'instagram_direct_message';
});

const allowedFileTypes = computed(() => {
  // Use default file types for private notes
  if (props.isOnPrivateNote) {
    return ALLOWED_FILE_TYPES;
  }

  let channelTypeValue = channelType.value || props.inbox?.channel_type;

  if (isAnInstagramChannel.value || isInstagramDM.value) {
    channelTypeValue = INBOX_TYPES.INSTAGRAM;
  }

  return getAllowedFileTypesByChannel({
    channelType: channelTypeValue,
    medium: props.inbox?.medium,
  });
});

const enableDragAndDrop = computed(() => {
  return !props.newConversationModalActive;
});

const audioRecorderPlayStopIcon = computed(() => {
  switch (props.recordingAudioState) {
    // playing paused recording stopped inactive destroyed
    case 'playing':
      return 'i-lucide-pause';
    case 'paused':
      return 'i-lucide-play';
    case 'stopped':
      return 'i-lucide-play';
    default:
      return 'i-lucide-circle-stop';
  }
});

const showMessageSignatureButton = computed(() => {
  return !props.isOnPrivateNote;
});

const sendWithSignature = computed(() => {
  return fetchSignatureFlagFromUISettings(channelType.value);
});

const signatureToggleTooltip = computed(() => {
  return sendWithSignature.value
    ? t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
    : t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
});

const enableInsertArticleInReply = computed(() => {
  return props.portalSlug;
});

const isFetchingAppIntegrations = computed(() => {
  return uiFlags.value.isFetching;
});

const quotedReplyToggleTooltip = computed(() => {
  return props.quotedReplyEnabled
    ? t('CONVERSATION.REPLYBOX.QUOTED_REPLY.DISABLE_TOOLTIP')
    : t('CONVERSATION.REPLYBOX.QUOTED_REPLY.ENABLE_TOOLTIP');
});

const toggleMessageSignature = () => {
  setSignatureFlagForInbox(channelType.value, !sendWithSignature.value);
};

const replaceText = text => {
  emit('replaceText', text);
};

const toggleInsertArticle = () => {
  emit('toggleInsertArticle');
};

onMounted(() => {
  ActiveStorage.start();
});
</script>

<template>
  <div
    class="flex justify-between py-3 ltr:pl-1.5 ltr:pr-3 rtl:pr-1.5 rtl:pl-3 border-t"
    :class="{ 'border-n-weak': !isNote, 'border-n-amber-4': isNote }"
  >
    <div class="items-center flex gap-1.5">
      <NextButton
        v-tooltip.top-end="t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        icon="i-lucide-smile-plus"
        slate
        ghost
        sm
        @click="toggleEmojiPicker"
      />
      <div
        v-if="showAttachButton"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <FileUpload
        ref="uploadRef"
        v-tooltip.top-end="t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
        input-id="conversationAttachment"
        :size="4096 * 4096"
        :accept="allowedFileTypes"
        :multiple="enableMultipleFileUpload"
        :drop="enableDragAndDrop"
        :drop-directory="false"
        :data="{
          direct_upload_url: '/rails/active_storage/direct_uploads',
          direct_upload: true,
        }"
        @input-file="onFileUpload"
      >
        <NextButton
          v-if="showAttachButton"
          v-tooltip.top-end="t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          icon="i-lucide-paperclip"
          slate
          ghost
          sm
        />
      </FileUpload>
      <div
        v-if="showAudioRecorderButton"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showAudioRecorderButton"
        v-tooltip.top-end="t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        :icon="!isRecordingAudio ? 'i-lucide-mic' : 'i-lucide-mic-off'"
        slate
        ghost
        sm
        @click="toggleAudioRecorder"
      />
      <div
        v-if="showAudioPlayStopButton"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showAudioPlayStopButton"
        :icon="audioRecorderPlayStopIcon"
        slate
        ghost
        sm
        :label="recordingAudioDurationText"
        @click="toggleAudioRecorderPlayPause"
      />
      <div
        v-if="showMessageSignatureButton"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showMessageSignatureButton"
        v-tooltip.top-end="signatureToggleTooltip"
        icon="i-lucide-signature"
        slate
        ghost
        sm
        @click="toggleMessageSignature"
      />
      <div
        v-if="showQuotedReplyToggle"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showQuotedReplyToggle"
        v-tooltip.top-end="quotedReplyToggleTooltip"
        icon="i-lucide-quote"
        :variant="quotedReplyEnabled ? 'faded' : 'ghost'"
        color="slate"
        sm
        :aria-pressed="quotedReplyEnabled"
        @click="$emit('toggleQuotedReply')"
      />
      <div
        v-if="enableWhatsAppTemplates"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="enableWhatsAppTemplates"
        v-tooltip.top-end="t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
        icon="i-ph-whatsapp-logo"
        slate
        ghost
        sm
        @click="$emit('selectWhatsappTemplate')"
      />
      <div
        v-if="enableContentTemplates"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="enableContentTemplates"
        v-tooltip.top-end="'Content Templates'"
        icon="i-ph-whatsapp-logo"
        slate
        ghost
        sm
        @click="$emit('selectContentTemplate')"
      />
      <div
        v-if="(isAWebWidgetInbox || isAPIInbox) && !isOnPrivateNote"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <VideoCallButton
        v-if="(isAWebWidgetInbox || isAPIInbox) && !isOnPrivateNote"
        :conversation-id="conversationId"
      />
      <div
        v-if="!isFetchingAppIntegrations"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <AIAssistanceButton
        v-if="!isFetchingAppIntegrations"
        :conversation-id="conversationId"
        :is-private-note="isOnPrivateNote"
        :message="message"
        @replace-text="replaceText"
      />
      <transition name="modal-fade">
        <div
          v-show="uploadRef && uploadRef.dropActive"
          class="flex fixed top-0 right-0 bottom-0 left-0 z-50 flex-col gap-2 justify-center items-center w-full h-full text-n-slate-12 bg-modal-backdrop-light dark:bg-modal-backdrop-dark"
        >
          <Icon icon="i-lucide-cloud-upload" class="size-10" />
          <h4 class="text-2xl break-words text-n-slate-12">
            {{ t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
      <div
        v-if="enableInsertArticleInReply"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="enableInsertArticleInReply"
        v-tooltip.top-end="t('HELP_CENTER.ARTICLE_SEARCH.OPEN_ARTICLE_SEARCH')"
        icon="i-lucide-text-initial"
        slate
        ghost
        sm
        @click="toggleInsertArticle"
      />
    </div>
    <div class="flex">
      <NextButton
        :label="sendButtonText"
        type="submit"
        sm
        color="blue"
        :disabled="isSendDisabled"
        class="flex-shrink-0 !text-xs"
        :class="{
          '!bg-n-solid-amber-button !text-[#251801] hover:enabled:!brightness-95 focus-visible:!brightness-95':
            isNote,
        }"
        @click="onSend"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
::v-deep .file-uploads {
  label {
    @apply cursor-pointer;
  }

  &:hover button {
    @apply enabled:bg-n-slate-9/20;
  }
}
</style>
