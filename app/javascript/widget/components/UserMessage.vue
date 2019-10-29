<template>
  <div class="user-message">
    <div class="message-wrap">
      <UserMessageBubble :message="message" />
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
    message: String,
    avatarUrl: String,
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.user-message {
  align-items: flex-end;
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  margin: 0 $space-smaller $space-micro auto;
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
    margin-bottom: $space-normal;
  }
  .message-wrap {
    margin-right: $space-small;
  }
}
</style>
