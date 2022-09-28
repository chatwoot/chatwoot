<template>
  <div
    class="agent-message-wrap"
    :class="{ 'has-response': hasRecordedResponse || isASubmittedForm }"
  >
    <div v-if="!isASubmittedForm" class="agent-message">
      <div class="avatar-wrap">
        <thumbnail
          v-if="message.showAvatar || hasRecordedResponse"
          :src="avatarUrl"
          size="24px"
          :username="agentName"
        />
      </div>
      <div class="message-wrap">
        <AgentMessageBubble
          v-if="shouldDisplayAgentMessage"
          :content-type="contentType"
          :message-content-attributes="messageContentAttributes"
          :message-id="message.id"
          :message-type="messageType"
          :message="message.content"
        />
        <div
          v-if="hasAttachments"
          class="chat-bubble has-attachment agent"
          :class="(wrapClass, $dm('bg-white', 'dark:bg-slate-50'))"
        >
          <div v-for="attachment in message.attachments" :key="attachment.id">
            <image-bubble
              v-if="attachment.file_type === 'image' && !hasImageError"
              :url="attachment.data_url"
              :thumb="attachment.data_url"
              :readable-time="readableTime"
              @error="onImageLoadError"
            />
            <audio v-else-if="attachment.file_type === 'audio'" controls>
              <source :src="attachment.data_url" />
            </audio>
            <file-bubble v-else :url="attachment.data_url" />
          </div>
        </div>
        <p
          v-if="message.showAvatar || hasRecordedResponse"
          class="agent-name"
          :class="$dm('text-slate-700', 'dark:text-slate-200')"
        >
          {{ agentName }}
        </p>
      </div>
    </div>

    <UserMessage v-if="hasRecordedResponse" :message="responseMessage" />
    <div v-if="isASubmittedForm">
      <UserMessage
        v-for="submittedValue in submittedFormValues"
        :key="submittedValue.id"
        :message="submittedValue"
      />
    </div>
  </div>
</template>

<script>
import UserMessage from 'widget/components/UserMessage';
import AgentMessageBubble from 'widget/components/AgentMessageBubble';
import timeMixin from 'dashboard/mixins/time';
import ImageBubble from 'widget/components/ImageBubble';
import FileBubble from 'widget/components/FileBubble';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import configMixin from '../mixins/configMixin';
import messageMixin from '../mixins/messageMixin';
import { isASubmittedFormMessage } from 'shared/helpers/MessageTypeHelper';
import darkModeMixin from 'widget/mixins/darkModeMixin.js';

export default {
  name: 'AgentMessage',
  components: {
    AgentMessageBubble,
    ImageBubble,
    Thumbnail,
    UserMessage,
    FileBubble,
  },
  mixins: [timeMixin, configMixin, messageMixin, darkModeMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      hasImageError: false,
    };
  },
  computed: {
    shouldDisplayAgentMessage() {
      if (
        this.contentType === 'input_select' &&
        this.messageContentAttributes.submitted_values &&
        !this.message.content
      ) {
        return false;
      }
      if (!this.message.content) return false;
      return true;
    },
    readableTime() {
      const { created_at: createdAt = '' } = this.message;
      return this.messageStamp(createdAt, 'LLL d yyyy, h:mm a');
    },
    messageType() {
      const { message_type: type = 1 } = this.message;
      return type;
    },
    contentType() {
      const { content_type: type = '' } = this.message;
      return type;
    },
    agentName() {
      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return 'Bot';
      }
      if (this.message.sender) {
        return this.message.sender.available_name || this.message.sender.name;
      }
      return 'Bot';
    },
    avatarUrl() {
      // eslint-disable-next-line
      const BotImage = require('dashboard/assets/images/chatwoot_bot.png');
      const displayImage = this.useInboxAvatarForBot
        ? this.inboxAvatarUrl
        : BotImage;

      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return displayImage;
      }

      return this.message.sender
        ? this.message.sender.avatar_url
        : displayImage;
    },
    hasRecordedResponse() {
      return (
        this.messageContentAttributes.submitted_email ||
        (this.messageContentAttributes.submitted_values &&
          !['form', 'input_csat'].includes(this.contentType))
      );
    },
    responseMessage() {
      if (this.messageContentAttributes.submitted_email) {
        return { content: this.messageContentAttributes.submitted_email };
      }

      if (this.messageContentAttributes.submitted_values) {
        if (this.contentType === 'input_select') {
          const [
            selectionOption = {},
          ] = this.messageContentAttributes.submitted_values;
          return { content: selectionOption.title || selectionOption.value };
        }
      }
      return '';
    },
    isASubmittedForm() {
      return isASubmittedFormMessage(this.message);
    },
    submittedFormValues() {
      return this.messageContentAttributes.submitted_values.map(
        submittedValue => ({
          id: submittedValue.name,
          content: submittedValue.value,
        })
      );
    },
    wrapClass() {
      return {
        'has-text': this.shouldDisplayAgentMessage,
      };
    },
  },
  watch: {
    message() {
      this.hasImageError = false;
    },
  },
  mounted() {
    this.hasImageError = false;
  },
  methods: {
    onImageLoadError() {
      this.hasImageError = true;
    },
  },
};
</script>
