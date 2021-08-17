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
          :class="wrapClass"
        >
          <div v-for="attachment in message.attachments" :key="attachment.id">
            <file-bubble
              v-if="attachment.file_type !== 'image'"
              :url="attachment.data_url"
            />
            <image-bubble
              v-else
              :url="attachment.data_url"
              :thumb="attachment.thumb_url"
              :readable-time="readableTime"
            />
          </div>
        </div>
        <p v-if="message.showAvatar || hasRecordedResponse" class="agent-name">
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
export default {
  name: 'AgentMessage',
  components: {
    AgentMessageBubble,
    ImageBubble,
    Thumbnail,
    UserMessage,
    FileBubble,
  },
  mixins: [timeMixin, configMixin, messageMixin],
  props: {
    message: {
      type: Object,
      default: () => {},
    },
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
          const [selectionOption = {}] =
            this.messageContentAttributes.submitted_values;
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
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.conversation-wrap {
  .agent-message {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    margin: 0 0 $space-micro $space-small;
    max-width: 88%;

    .avatar-wrap {
      height: $space-medium;
      width: $space-medium;
      flex-shrink: 0;

      .user-thumbnail-box {
        margin-top: -$space-large;
      }
    }

    .message-wrap {
      flex-grow: 1;
      flex-shrink: 0;
      margin-left: $space-small;
      max-width: 90%;
    }
  }

  .agent-name {
    color: $color-body;
    font-size: $font-size-small;
    font-weight: $font-weight-medium;
    margin: $space-small 0;
    padding-left: $space-micro;
  }

  .has-attachment {
    padding: 0;
    overflow: hidden;

    &.has-text {
      margin-top: $space-smaller;
    }
  }

  .agent-message-wrap {
    + .agent-message-wrap {
      margin-top: $space-micro;

      .agent-message .chat-bubble {
        border-top-left-radius: $space-smaller;
      }
    }

    + .user-message-wrap {
      margin-top: $space-normal;
    }

    &.has-response + .user-message-wrap {
      margin-top: $space-micro;
      .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
    }

    &.has-response + .agent-message-wrap {
      margin-top: $space-normal;
    }
  }
}
</style>
