<template>
  <div class="user-message">
    <div class="message-wrap">
      <UserMessageBubble :message="message" :status="status" />
    </div>
  </div>
</template>

<script>
import UserMessageBubble from 'widget/components/UserMessageBubble.vue';

export default {
  name: 'UserMessage',
  components: {
    UserMessageBubble,
  },
  props: {
    avatarUrl: String,
    message: String,
    status: {
      type: String,
      default: '',
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style lang="scss">
@import '~widget/assets/scss/variables.scss';
.conversation-wrap {
  .user-message {
    align-items: flex-end;
    display: flex;
    flex-direction: row;
    justify-content: flex-end;
    margin: 0 $space-smaller $space-micro auto;
    max-width: 85%;
    text-align: right;

    & + .user-message {
      margin-bottom: $space-micro;
      .chat-bubble {
        border-top-right-radius: $space-smaller;
      }
      .user-avatar {
        visibility: hidden;
      }
      .agent-name {
        display: none;
      }
    }
    & + .agent-message {
      margin-top: $space-normal;
    }
    .message-wrap {
      margin-right: $space-small;
    }
  }
}
</style>
