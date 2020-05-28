<template>
  <UserMessage v-if="isUserMessage" :message="message" />
  <AgentMessage v-else-if="showTemplateMessage" :message="message" />
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
    message: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    isUserMessage() {
      return this.message.message_type === MESSAGE_TYPE.INCOMING;
    },
    showTemplateMessage() {
      const isTemplate = this.message.message_type === MESSAGE_TYPE.TEMPLATE;
      const isPrimaryContact =
        window.chatwootPubsubToken === window.contactPubsubToken;

      if (isTemplate) {
        return isPrimaryContact;
      }
      return true;
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
