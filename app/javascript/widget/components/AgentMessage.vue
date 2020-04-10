<template>
  <div class="agent-bubble">
    <div class="agent-message">
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
          v-if="showTextBubble && shouldDisplayAgentMessage"
          :content-type="contentType"
          :message-content-attributes="messageContentAttributes"
          :message-id="message.id"
          :message-type="messageType"
          :message="message.content"
        />
        <div v-if="hasAttachment" class="chat-bubble has-attachment agent">
          <file-bubble
            v-if="
              message.attachment && message.attachment.file_type !== 'image'
            "
            :url="message.attachment.data_url"
          />
          <image-bubble
            v-else
            :url="message.attachment.data_url"
            :thumb="message.attachment.thumb_url"
            :readable-time="readableTime"
          />
        </div>
        <p v-if="message.showAvatar || hasRecordedResponse" class="agent-name">
          {{ agentName }}
        </p>
      </div>
    </div>

    <UserMessage v-if="hasRecordedResponse" :message="responseMessage" />
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

export default {
  name: 'AgentMessage',
  components: {
    AgentMessageBubble,
    ImageBubble,
    Thumbnail,
    UserMessage,
    FileBubble,
  },
  mixins: [timeMixin],
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
      return true;
    },
    hasAttachment() {
      return !!this.message.attachment;
    },
    showTextBubble() {
      const { message } = this;
      return !message.attachment;
    },
    readableTime() {
      const { created_at: createdAt = '' } = this.message;
      return this.messageStamp(createdAt);
    },
    messageType() {
      const { message_type: type = 1 } = this.message;
      return type;
    },
    contentType() {
      const { content_type: type = '' } = this.message;
      return type;
    },
    messageContentAttributes() {
      const { content_attributes: attribute = {} } = this.message;
      return attribute;
    },
    agentName() {
      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return 'Bot';
      }

      return this.message.sender ? this.message.sender.name : 'Bot';
    },
    avatarUrl() {
      // eslint-disable-next-line
      const BotImage = require('dashboard/assets/images/chatwoot_bot.png')
      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return BotImage;
      }

      return this.message.sender ? this.message.sender.avatar_url : BotImage;
    },
    hasRecordedResponse() {
      return (
        this.messageContentAttributes.submitted_email ||
        (this.messageContentAttributes.submitted_values &&
          this.contentType !== 'form')
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
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.conversation-wrap {
  .agent-bubble {
    margin-bottom: $space-micro;
    & + .agent-bubble {
      .agent-message {
        .chat-bubble {
          border-top-left-radius: $space-smaller;
        }
      }
    }
  }

  .agent-message {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    margin: 0 0 $space-micro $space-small;
    max-width: 88%;

    & + .user-message {
      margin-top: $space-one;
    }

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
  }
}
</style>
