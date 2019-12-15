<template>
  <UserMessage
    v-if="isUserMessage"
    :message="message.content"
    :status="message.status"
  />
  <AgentMessage
    v-else
    :agent-name="agentName"
    :avatar-url="avatarUrl"
    :content-type="message.content_type"
    :message-content-attributes="message.content_attributes"
    :message-id="message.id"
    :message-type="message.message_type"
    :message="message.content"
    :show-avatar="message.showAvatar"
  />
</template>

<script>
import AgentMessage from 'widget/components/AgentMessage.vue';
import UserMessage from 'widget/components/UserMessage.vue';
import { MESSAGE_TYPE } from 'widget/helpers/constants';

export default {
  components: {
    AgentMessage,
    UserMessage,
  },
  props: {
    message: Object,
    showAvatar: Boolean,
  },
  computed: {
    isUserMessage() {
      return this.message.message_type === MESSAGE_TYPE.INCOMING;
    },
    agentName() {
      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return 'Bot';
      }

      return this.message.sender ? this.message.sender.name : '';
    },
    avatarUrl() {
      if (this.message.message_type === MESSAGE_TYPE.TEMPLATE) {
        return 'Bot';
      }

      return this.message.sender ? this.message.sender.avatar_url : '';
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
