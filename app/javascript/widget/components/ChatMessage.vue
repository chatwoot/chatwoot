<template>
  <UserMessage
    v-if="isUserMessage"
    :message="message.content"
    :status="message.status"
  />
  <AgentMessage v-else :agent-name="agentName" :message="message.content" />
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
  },
  computed: {
    isUserMessage() {
      return this.message.message_type === MESSAGE_TYPE.INCOMING;
    },
    agentName() {
      return this.message.sender ? this.message.sender.name : '';
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
