<script>
import { ref } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import FileUpload from 'vue-upload-component';
import * as ActiveStorage from 'activestorage';
import inboxMixin from 'shared/mixins/inboxMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { getAllowedFileTypesByChannel } from '@chatwoot/utils';
import { ALLOWED_FILE_TYPES } from 'shared/constants/messages';
import VideoCallButton from '../VideoCallButton.vue';
import AIAssistanceButton from '../AIAssistanceButton.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { mapGetters } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  name: 'ReplyBottomPanel',
  components: { NextButton, FileUpload, VideoCallButton, AIAssistanceButton },
  mixins: [inboxMixin],
  props: {
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
    // inbox prop is used in /mixins/inboxMixin,
    // remove this props when refactoring to composable if not needed
    // eslint-disable-next-line vue/no-unused-properties
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
    showEditorToggle: {
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
  },
  emits: [
    'replaceText',
    'toggleInsertArticle',
    'toggleEditor',
    'selectWhatsappTemplate',
    'selectContentTemplate',
    'toggleQuotedReply',
  ],
  setup() {
    const { setSignatureFlagForInbox, fetchSignatureFlagFromUISettings } =
      useUISettings();

    const uploadRef = ref(false);

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

    return {
      setSignatureFlagForInbox,
      fetchSignatureFlagFromUISettings,
      uploadRef,
    };
  },
  data() {
    return {
      ALLOWED_FILE_TYPES,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      uiFlags: 'integrations/getUIFlags',
    }),
    showAttachButton() {
      return this.showFileUpload || this.isNote;
    },
    showAudioRecorderButton() {
      if (this.isALineChannel) {
        return false;
      }
      // Disable audio recorder for safari browser as recording is not supported
      // const isSafari = /^((?!chrome|android|crios|fxios).)*safari/i.test(
      //   navigator.userAgent
      // );

      return (
        this.isFeatureEnabledonAccount(
          this.accountId,
          FEATURE_FLAGS.VOICE_RECORDER
        ) && this.showAudioRecorder
        // !isSafari
      );
    },
    showAudioPlayStopButton() {
      return this.showAudioRecorder && this.isRecordingAudio;
    },
    isInstagramDM() {
      return this.conversationType === 'instagram_direct_message';
    },
    allowedFileTypes() {
      // Use default file types for private notes
      if (this.isOnPrivateNote) {
        return this.ALLOWED_FILE_TYPES;
      }

      let channelType = this.channelType || this.inbox?.channel_type;

      if (this.isAnInstagramChannel || this.isInstagramDM) {
        channelType = INBOX_TYPES.INSTAGRAM;
      }

      return getAllowedFileTypesByChannel({
        channelType,
        medium: this.inbox?.medium,
      });
    },
    enableDragAndDrop() {
      return !this.newConversationModalActive;
    },
    audioRecorderPlayStopIcon() {
      switch (this.recordingAudioState) {
        // playing paused recording stopped inactive destroyed
        case 'playing':
          return 'i-ph-pause';
        case 'paused':
          return 'i-ph-play';
        case 'stopped':
          return 'i-ph-play';
        default:
          return 'i-ph-stop';
      }
    },
    showMessageSignatureButton() {
      return !this.isOnPrivateNote;
    },
    sendWithSignature() {
      // channelType is sourced from inboxMixin
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    signatureToggleTooltip() {
      return this.sendWithSignature
        ? this.$t('CONVERSATION.FOOTER.DISABLE_SIGN_TOOLTIP')
        : this.$t('CONVERSATION.FOOTER.ENABLE_SIGN_TOOLTIP');
    },
    enableInsertArticleInReply() {
      return this.portalSlug;
    },
    isFetchingAppIntegrations() {
      return this.uiFlags.isFetching;
    },
    quotedReplyToggleTooltip() {
      return this.quotedReplyEnabled
        ? this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.DISABLE_TOOLTIP')
        : this.$t('CONVERSATION.REPLYBOX.QUOTED_REPLY.ENABLE_TOOLTIP');
    },
  },
  mounted() {
    ActiveStorage.start();
  },
  methods: {
    toggleMessageSignature() {
      this.setSignatureFlagForInbox(this.channelType, !this.sendWithSignature);
    },
    replaceText(text) {
      this.$emit('replaceText', text);
    },
    toggleInsertArticle() {
      this.$emit('toggleInsertArticle');
    },
  },
};
</script>

<template>
  <div
    class="flex justify-between py-3 ltr:pl-1.5 ltr:pr-3 rtl:pr-1.5 rtl:pl-3 border-t"
    :class="{ 'border-n-weak': !isNote, 'border-n-amber-4': isNote }"
  >
    <div class="items-center flex gap-1.5">
      <NextButton
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        icon="i-ph-smiley-sticker"
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
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
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
          v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
          icon="i-ph-paperclip"
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
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_AUDIORECORDER_ICON')"
        :icon="!isRecordingAudio ? 'i-ph-microphone' : 'i-ph-microphone-slash'"
        slate
        ghost
        sm
        @click="toggleAudioRecorder"
      />
      <div
        v-if="showEditorToggle"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showEditorToggle"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_FORMAT_ICON')"
        icon="i-ph-quotes"
        slate
        ghost
        sm
        @click="$emit('toggleEditor')"
      />
      <div
        v-if="showAudioPlayStopButton"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="showAudioPlayStopButton"
        v-tooltip.top-end="$t('CONVERSATION.REPLYBOX.TIP_FORMAT_ICON')"
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
        icon="i-ph-signature"
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
        icon="i-ph-quotes"
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
        v-tooltip.top-end="$t('CONVERSATION.FOOTER.WHATSAPP_TEMPLATES')"
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
          class="flex fixed top-0 right-0 bottom-0 left-0 z-20 flex-col gap-2 justify-center items-center w-full h-full text-n-slate-12 bg-modal-backdrop-light dark:bg-modal-backdrop-dark"
        >
          <fluent-icon icon="cloud-backup" size="40" />
          <h4 class="text-2xl break-words text-n-slate-12">
            {{ $t('CONVERSATION.REPLYBOX.DRAG_DROP') }}
          </h4>
        </div>
      </transition>
      <div
        v-if="enableInsertArticleInReply"
        class="h-3 border-r border-n-strong flex-shrink-0 rounded-full"
      />
      <NextButton
        v-if="enableInsertArticleInReply"
        v-tooltip.top-end="$t('HELP_CENTER.ARTICLE_SEARCH.OPEN_ARTICLE_SEARCH')"
        icon="i-ph-article-ny-times"
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
        :color="isNote ? 'amber' : 'blue'"
        :disabled="isSendDisabled"
        class="flex-shrink-0"
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
