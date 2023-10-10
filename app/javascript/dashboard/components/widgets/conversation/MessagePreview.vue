<template>
  <p
    class="overflow-hidden text-sm text-slate-700 dark:text-slate-200 text-ellipsis whitespace-nowrap"
  >
    <template v-if="showMessageType">
      <fluent-icon
        v-if="isMessagePrivate"
        size="16"
        class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
        icon="lock-closed"
      />
      <fluent-icon
        v-else-if="messageByAgent"
        size="16"
        class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
        icon="arrow-reply"
      />
      <fluent-icon
        v-else-if="isMessageAnActivity"
        size="16"
        class="-mt-0.5 align-middle text-slate-600 dark:text-slate-300 inline-block"
        icon="info"
      />
    </template>
    <span v-if="message.content">
      {{ parsedLastMessage }}
    </span>
    <span v-else-if="message.attachments">
      <fluent-icon
        v-if="attachmentIcon"
        size="16"
        class="-mt-0.5 align-middle inline-block text-slate-600 dark:text-slate-300"
        :icon="attachmentIcon"
      />
      {{ $t(`${attachmentMessageContent}`) }}
    </span>
    <span v-else>
      {{ $t('CHAT_LIST.NO_CONTENT') }}
    </span>
  </p>
</template>

<script>
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { ATTACHMENT_ICONS } from 'shared/constants/messages';

export default {
  name: 'MessagePreview',
  mixins: [messageFormatterMixin],
  props: {
    message: {
      type: Object,
      required: true,
    },
    showMessageType: {
      type: Boolean,
      default: true,
    },
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
  },
};
</script>
