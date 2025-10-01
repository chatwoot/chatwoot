<script>
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants.js';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { ATTACHMENT_ICONS } from 'shared/constants/messages';

export default {
  name: 'MessagePreview',
  props: {
    message: {
      type: Object,
      required: true,
    },
    conversation: {
      type: Object,
      default: () => ({}),
    },
    showMessageType: {
      type: Boolean,
      default: true,
    },
    defaultEmptyMessage: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { getPlainText } = useMessageFormatter();
    return {
      getPlainText,
    };
  },
  computed: {
    shouldShowCallStatus() {
      // Show call status for voice channels if present on conversation or message
      if (!this.isVoiceChannel) return false;
      const convHas = !!this.conversation?.additional_attributes?.call_status;
      const msgHas = !!this.message?.content_attributes?.data?.status;
      return convHas || msgHas;
    },
    messageByAgent() {
      const { message_type: messageType } = this.message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    },
    isMessageAnActivity() {
      const { message_type: messageType } = this.message;
      return messageType === MESSAGE_TYPE.ACTIVITY;
    },
    isMessagePrivate() {
      const { private: isPrivate } = this.message;
      return isPrivate;
    },
    // Simple check: Is this a voice channel conversation?
    isVoiceChannel() {
      return (
        this.conversation?.channel === 'Channel::Voice' ||
        this.conversation?.meta?.channel === 'Channel::Voice' ||
        this.conversation?.meta?.inbox?.channel_type === 'Channel::Voice'
      );
    },
    // Check if this is a voice call message
    isVoiceCall() {
      const ct = this.message?.content_type;
      return ct === CONTENT_TYPES.VOICE_CALL || ct === 12;
    },
    // Get call direction for voice calls (authoritative: conversation-level)
    isIncomingCall() {
      if (!this.isVoiceChannel) return false;
      const convDir = this.conversation?.additional_attributes?.call_direction;
      return convDir === 'inbound';
    },
    // Get call status (Twilio-native)
    callStatus() {
      if (!this.isVoiceChannel) return null;
      return this.message?.content_attributes?.data?.status || null;
    },
    parsedLastMessage() {
      // For voice calls, return status text
      if (this.isVoiceChannel) {
        // Get status-based text
        const status = this.callStatus;
        const isIncoming = this.isIncomingCall;

        // Return appropriate status text based on call status and direction
        if (status === 'in-progress') {
          // return last message content if message is not activity and not voice call
          if (!this.isMessageAnActivity && !this.isVoiceCall) {
            return this.getPlainText(this.message.content);
          }
          return this.$t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
        }

        if (isIncoming) {
          if (status === 'ringing') {
            return this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
          }

          if (status === 'no-answer') {
            return this.$t('CONVERSATION.VOICE_CALL.MISSED_CALL');
          }

          if (status === 'completed' || status === 'canceled') {
            return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
          }
        } else {
          if (status === 'ringing') {
            return this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
          }

          if (status === 'no-answer' || status === 'busy' || status === 'failed') {
            return this.$t('CONVERSATION.VOICE_CALL.NO_ANSWER');
          }

          if (status === 'completed' || status === 'canceled') {
            return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
          }
        }

        // Default fallback based on direction
        return isIncoming
          ? this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL')
          : this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
      }

      // Default behavior for non-voice calls
      const { content_attributes: contentAttributes } = this.message;
      const { email: { subject } = {} } = contentAttributes || {};
      return this.getPlainText(subject || this.message.content);
    },
    lastMessageFileType() {
      const [{ file_type: fileType } = {}] = this.message.attachments;
      return fileType;
    },
    attachmentIcon() {
      return ATTACHMENT_ICONS[this.lastMessageFileType];
    },
    attachmentMessageContent() {
      return `CHAT_LIST.ATTACHMENTS.${this.lastMessageFileType}.CONTENT`;
    },
    isMessageSticker() {
      return this.message && this.message.content_type === 'sticker';
    },
  },
};
</script>

<template>
  <div class="overflow-hidden text-ellipsis whitespace-nowrap">
    <!-- Always show call status for voice channels if present -->
    <template v-if="shouldShowCallStatus">
      <span
        class="-mt-0.5 align-middle inline-block mr-1"
        :class="{
          'text-red-600 dark:text-red-400':
            callStatus === 'no-answer' || callStatus === 'busy' || callStatus === 'failed',
          'text-green-600 dark:text-green-400':
            callStatus === 'in-progress' || callStatus === 'ringing',
          'text-n-slate-11': callStatus === 'completed' || callStatus === 'canceled',
        }"
      >
        <!-- Missed call icon -->
        <i
          v-if="callStatus === 'no-answer' || callStatus === 'busy' || callStatus === 'failed'"
          class="i-ph-phone-x text-base"
        />
        <!-- Active call icon -->
        <i
          v-else-if="callStatus === 'in-progress'"
          class="i-ph-phone-call text-base"
        />
        <!-- Incoming call icon -->
        <i
          v-else-if="
            ((callStatus === 'completed' || callStatus === 'canceled') && isIncomingCall) || isIncomingCall
          "
          class="i-ph-phone-incoming text-base"
        />
        <!-- Outgoing call icon -->
        <i v-else class="i-ph-phone-outgoing text-base" />
      </span>
      <span>{{ parsedLastMessage }}</span>
    </template>
    <template v-else>
      <template v-if="showMessageType">
        <fluent-icon
          v-if="isMessagePrivate"
          size="16"
          class="-mt-0.5 align-middle text-n-slate-11 inline-block"
          icon="lock-closed"
        />
        <!-- Voice calls with phosphor icons (non-filled variants) -->
        <span
          v-else-if="isVoiceCall"
          class="-mt-0.5 align-middle inline-block mr-1"
          :class="{
            'text-red-600 dark:text-red-400':
              callStatus === 'no-answer' || callStatus === 'busy' || callStatus === 'failed',
            'text-green-600 dark:text-green-400':
              callStatus === 'in-progress' || callStatus === 'ringing',
            'text-n-slate-11': callStatus === 'completed' || callStatus === 'canceled',
          }"
        >
          <!-- Missed call icon -->
          <i
            v-if="callStatus === 'no-answer' || callStatus === 'busy' || callStatus === 'failed'"
            class="i-ph-phone-x text-base"
          />
          <!-- Active call icon -->
          <i
            v-else-if="callStatus === 'in-progress'"
            class="i-ph-phone-call text-base"
          />
          <!-- Incoming call icon -->
          <i
            v-else-if="
              (callStatus === 'ended' && isIncomingCall) || isIncomingCall
            "
            class="i-ph-phone-incoming text-base"
          />
          <!-- Outgoing call icon -->
          <i v-else class="i-ph-phone-outgoing text-base" />
        </span>
        <fluent-icon
          v-else-if="messageByAgent"
          size="16"
          class="-mt-0.5 align-middle text-n-slate-11 inline-block"
          icon="arrow-reply"
        />
        <fluent-icon
          v-else-if="isMessageAnActivity"
          size="16"
          class="-mt-0.5 align-middle text-n-slate-11 inline-block"
          icon="info"
        />
      </template>
      <span v-if="message.content && isMessageSticker">
        <fluent-icon
          size="16"
          class="-mt-0.5 align-middle inline-block text-n-slate-11"
          icon="image"
        />
        {{ $t('CHAT_LIST.ATTACHMENTS.image.CONTENT') }}
      </span>
      <span v-else-if="message.content || isVoiceCall">
        {{ parsedLastMessage }}
      </span>
      <span v-else-if="message.attachments">
        <fluent-icon
          v-if="attachmentIcon && showMessageType"
          size="16"
          class="-mt-0.5 align-middle inline-block text-n-slate-11"
          :icon="attachmentIcon"
        />
        {{ $t(`${attachmentMessageContent}`) }}
      </span>
      <span v-else>
        {{ defaultEmptyMessage || $t('CHAT_LIST.NO_CONTENT') }}
      </span>
    </template>
  </div>
</template>
