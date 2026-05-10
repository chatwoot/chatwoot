<script>
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
    parsedLastMessage() {
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
    messageDeliveryStatus() {
      // Chatwoot message status: sent=0, delivered=1, read=2, failed=3
      return this.message?.status || 'sent';
    },
    isDelivered() {
      return this.messageDeliveryStatus === 'delivered';
    },
    isRead() {
      return this.messageDeliveryStatus === 'read';
    },
    isFailed() {
      return this.messageDeliveryStatus === 'failed';
    },
    tickColor() {
      if (this.isRead) return '#53bdeb';
      return '#8696a0';
    },
  },
};
</script>

<template>
  <div
    class="overflow-hidden text-ellipsis whitespace-nowrap font-bubble-text"
    dir="auto"
    style="unicode-bidi: plaintext"
  >
    <template v-if="showMessageType">
      <fluent-icon
        v-if="isMessagePrivate"
        size="16"
        class="-mt-0.5 align-middle text-n-slate-11 inline-block"
        icon="lock-closed"
      />
      <template v-else-if="messageByAgent">
        <svg
          v-if="isFailed"
          class="-mt-0.5 align-middle inline-block"
          width="14"
          height="14"
          viewBox="0 0 14 14"
        >
          <circle
            cx="7"
            cy="7"
            r="6"
            fill="none"
            stroke="#e74c3c"
            stroke-width="1.5"
          />
          <path
            d="M7 4v3.5M7 9v.5"
            stroke="#e74c3c"
            stroke-width="1.5"
            stroke-linecap="round"
          />
        </svg>
        <svg
          v-else-if="isRead || isDelivered"
          class="-mt-0.5 align-middle inline-block"
          width="18"
          height="12"
          viewBox="0 0 18 12"
        >
          <path
            d="M1.5 6.5L5 10L12.5 1.5"
            fill="none"
            :stroke="tickColor"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
          <path
            d="M6 6.5L9.5 10L17 1.5"
            fill="none"
            :stroke="tickColor"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
        <svg
          v-else
          class="-mt-0.5 align-middle inline-block"
          width="14"
          height="12"
          viewBox="0 0 14 12"
        >
          <path
            d="M1.5 6.5L5 10L12.5 1.5"
            fill="none"
            stroke="#8696a0"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </template>
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
    <span v-else-if="message.content">
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
  </div>
</template>
