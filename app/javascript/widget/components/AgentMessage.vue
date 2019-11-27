<template>
  <div class="agent-message">
    <div class="avatar-wrap">
      <UserAvatar size="small" :src="avatarUrl" />
    </div>
    <div class="message-wrap">
      <h5 class="agent-name">
        {{ agentName }}
      </h5>
      <AgentMessageBubble :message="message" />
    </div>
  </div>
</template>

<script>
import UserAvatar from 'widget/components/UserAvatar.vue';
import AgentMessageBubble from 'widget/components/AgentMessageBubble.vue';

export default {
  name: 'AgentMessage',
  components: {
    UserAvatar,
    AgentMessageBubble,
  },
  props: {
    message: String,
    avatarUrl: String,
    agentName: String,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.conversation-wrap {
  .agent-message {
    display: flex;
    flex-direction: row;
    justify-content: flex-start;
    align-items: flex-end;
    margin: 0 0 $space-micro $space-small;
    max-width: 88%;

    & + .agent-message {
      margin-bottom: $space-smaller;

      .chat-bubble {
        border-top-left-radius: $space-smaller;
      }

      .user-avatar {
        visibility: hidden;
      }

      .agent-name {
        display: none;
      }
    }

    & + .user-message {
      margin-top: $space-normal;
    }

    .avatar-wrap {
      flex-shrink: 1;
      flex-grow: 0;
    }

    .message-wrap {
      max-width: 90%;
      flex-shrink: 0;
      flex-grow: 1;
      margin-left: $space-small;

      .agent-name {
        font-weight: $font-weight-medium;
        margin-bottom: $space-smaller;
        margin-left: $space-two;
        color: $color-body;
      }
    }
  }
}
</style>
