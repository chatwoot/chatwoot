<template>
  <UserMessage
    v-if="isUserMessage"
    :id="`cwmsg-${message.id}`"
    :message="message"
    :reply-to="replyTo"
  />
  <AgentMessage
    v-else
    :id="`cwmsg-${message.id}`"
    :message="message"
    :reply-to="replyTo"
  />
</template>

<script>
import AgentMessage from 'widget/components/AgentMessage.vue';
import UserMessage from 'widget/components/UserMessage.vue';
import { mapGetters } from 'vuex';
import { MESSAGE_TYPE } from 'widget/helpers/constants';

export default {
  components: {
    AgentMessage,
    UserMessage,
  },
  props: {
    message: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    ...mapGetters({
      allMessages: 'conversation/getConversation',
    }),
    isUserMessage() {
      return this.message.message_type === MESSAGE_TYPE.INCOMING;
    },
    replyTo() {
      const replyTo = this.message?.content_attributes?.in_reply_to;
      return replyTo ? this.allMessages[replyTo] : null;
    },
  },
};
</script>

<style scoped lang="scss">
.message-wrap {
  display: flex;
  flex-direction: row;
  align-items: flex-end;
  max-width: 90%;
}
</style>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-bubble .message-content,
.chat-bubble.user {
  p code {
    background-color: var(--s-75);
    display: inline-block;
    line-height: 1;

    border-radius: $border-radius-small;
    padding: $space-smaller;
  }

  pre {
    overflow-y: auto;
    background-color: var(--s-75);
    border-color: var(--s-75);
    color: var(--s-800);
    border-radius: $border-radius-normal;
    padding: $space-small;
    margin-top: $space-smaller;
    margin-bottom: $space-small;
    display: block;
    line-height: 1.7;
    white-space: pre-wrap;

    code {
      background-color: transparent;
      color: var(--s-800);
      padding: 0;
    }
  }

  blockquote {
    border-left: $space-micro solid var(--s-75);
    color: var(--s-800);
    padding: $space-smaller $space-small;
    margin: $space-smaller 0;
    padding: $space-small $space-small 0 $space-normal;
  }
}

@media (prefers-color-scheme: dark) {
  .chat-bubble.agent.has-dark-mode {
    blockquote {
      border-color: var(--s-200);
      color: var(--s-50);
    }
  }
}
</style>
