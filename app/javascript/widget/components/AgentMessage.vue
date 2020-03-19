<template>
  <div class="agent-bubble">
    <div class="agent-message">
      <div class="avatar-wrap">
        <thumbnail
          v-if="showAvatar || hasRecordedResponse"
          :src="avatarUrl"
          size="24px"
          :username="agentName"
        />
      </div>
      <div class="message-wrap">
        <AgentMessageBubble
          :content-type="contentType"
          :message-content-attributes="messageContentAttributes"
          :message-id="messageId"
          :message-type="messageType"
          :message="message"
        />
        <p v-if="showAvatar || hasRecordedResponse" class="agent-name">
          {{ agentName }}
        </p>
      </div>
    </div>

    <UserMessage v-if="hasRecordedResponse" :message="responseMessage" />
  </div>
</template>

<script>
import AgentMessageBubble from 'widget/components/AgentMessageBubble.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import UserMessage from './UserMessage.vue';

export default {
  name: 'AgentMessage',
  components: {
    AgentMessageBubble,
    Thumbnail,
    UserMessage,
  },
  props: {
    message: String,
    avatarUrl: String,
    agentName: String,
    showAvatar: Boolean,
    contentType: {
      type: String,
      default: '',
    },
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    messageType: {
      type: Number,
      default: 1,
    },
    messageId: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    hasRecordedResponse() {
      return (
        this.messageContentAttributes.submitted_email ||
        (this.messageContentAttributes.submitted_values &&
          this.contentType !== 'form')
      );
    },
    responseMessage() {
      if (this.messageContentAttributes.submitted_email) {
        return this.messageContentAttributes.submitted_email;
      }

      if (this.messageContentAttributes.submitted_values) {
        if (this.contentType === 'input_select') {
          const [
            selectionOption = {},
          ] = this.messageContentAttributes.submitted_values;
          return selectionOption.title || selectionOption.value;
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
      .chat-bubble {
        border-top-left-radius: $space-smaller;
      }

      .user-message {
        .chat-bubble {
          border-top-left-radius: $space-two;
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
      margin-top: $space-normal;
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
}
</style>
