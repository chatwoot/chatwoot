<template>
  <div class="agent-message">
    <div class="avatar-wrap">
      <thumbnail
        v-if="showAvatar"
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
      <p v-if="showAvatar" class="agent-name">
        {{ agentName }}
      </p>
    </div>
  </div>
</template>

<script>
import AgentMessageBubble from 'widget/components/AgentMessageBubble.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';

export default {
  name: 'AgentMessage',
  components: {
    AgentMessageBubble,
    Thumbnail,
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

    & + .agent-message {
      margin-bottom: $space-micro;

      .chat-bubble {
        border-top-left-radius: $space-smaller;
      }
    }

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
