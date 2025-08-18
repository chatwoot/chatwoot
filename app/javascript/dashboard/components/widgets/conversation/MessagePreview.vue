<script>
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { ATTACHMENT_ICONS } from 'shared/constants/messages';
import { normalizeStatus } from 'dashboard/helper/voice';

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
        this.conversation?.meta?.channel === 'Channel::Voice' ||
        this.conversation?.meta?.inbox?.channel_type === 'Channel::Voice'
      );
    },
    // Check if this is a voice call message
    isVoiceCall() {
      return this.message?.content_type === 'voice_call';
    },
    // Get call direction for voice calls
    isIncomingCall() {
      if (!this.isVoiceChannel) return false;

      // Prefer conversation-level call direction
      const convDir = this.conversation?.additional_attributes?.call_direction;
      if (convDir) return convDir === 'inbound';

      // Fallback to last message direction if present
      const msgDir = this.message?.content_attributes?.data?.call_direction;
      if (msgDir) return msgDir === 'inbound';

      return false;
    },
    // Get normalized call status
    callStatus() {
      if (!this.isVoiceChannel) return null;

      // Prefer conversation-level status
      const convStatus = this.conversation?.additional_attributes?.call_status;
      if (convStatus) return normalizeStatus(convStatus);

      // Fallback to last message status if available
      const msgStatus = this.message?.content_attributes?.data?.status;
      if (msgStatus) return normalizeStatus(msgStatus);

      return null;
    },
    // Voice call icon based on status
    voiceCallIcon() {
      if (!this.isVoiceChannel) return null;

      const status = this.callStatus;
      const isIncoming = this.isIncomingCall;

      if (status === 'missed' || status === 'no_answer') {
        return 'phone-missed-call';
      }

      if (status === 'in_progress') {
        return 'phone-in-talk';
      }

      if (status === 'ended') {
        return isIncoming ? 'phone-incoming' : 'phone-outgoing';
      }

      if (status === 'ringing') {
        return isIncoming ? 'phone-incoming' : 'phone-outgoing';
      }

      // Default based on direction
      return isIncoming ? 'phone-incoming' : 'phone-outgoing';
    },
    parsedLastMessage() {
      // For voice calls, return status text
      if (this.isVoiceChannel) {
        // Get status-based text
        const status = this.callStatus;
        const isIncoming = this.isIncomingCall;

        // Return appropriate status text based on call status and direction
        if (status === 'in_progress') {
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

          if (status === 'missed') {
            return this.$t('CONVERSATION.VOICE_CALL.MISSED_CALL');
          }

          if (status === 'ended') {
            return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
          }
        } else {
          if (status === 'ringing') {
            return this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
          }

          if (status === 'no_answer') {
            return this.$t('CONVERSATION.VOICE_CALL.NO_ANSWER');
          }

          if (status === 'ended') {
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
            callStatus === 'missed' || callStatus === 'no_answer',
          'text-green-600 dark:text-green-400':
            callStatus === 'in_progress' || callStatus === 'ringing',
          'text-n-slate-11': callStatus === 'ended',
        }"
      >
        <!-- Missed call icon -->
        <i
          v-if="callStatus === 'missed' || callStatus === 'no_answer'"
          class="i-ph-phone-x text-base"
        />
        <!-- Active call icon -->
        <i
          v-else-if="callStatus === 'in_progress'"
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
              callStatus === 'missed' || callStatus === 'no_answer',
            'text-green-600 dark:text-green-400':
              callStatus === 'in_progress' || callStatus === 'ringing',
            'text-n-slate-11': callStatus === 'ended',
          }"
        >
          <!-- Missed call icon -->
          <i
            v-if="callStatus === 'missed' || callStatus === 'no_answer'"
            class="i-ph-phone-x text-base"
          />
          <!-- Active call icon -->
          <i
            v-else-if="callStatus === 'in_progress'"
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
