<template>
  <div>
    <div v-if="!isCards && !isOptions && !isForm" class="chat-bubble agent">
      <span v-html="formatMessage(message)"></span>
      <email-input
        v-if="isTemplateEmail"
        :message-id="messageId"
        :message-content-attributes="messageContentAttributes"
      />
    </div>
    <div v-if="isOptions">
      <chat-options :title="message" :options="messageContentAttributes.items">
      </chat-options>
    </div>
    <chat-form v-if="isForm" :items="messageContentAttributes.items">
    </chat-form>
    <div v-if="isCards">
      <chat-card
        v-for="item in messageContentAttributes.items"
        :key="item.title"
        :media-url="item.media_url"
        :title="item.title"
        :description="item.description"
        :actions="item.actions"
      >
      </chat-card>
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import ChatCard from 'shared/components/ChatCard';
import ChatForm from 'shared/components/ChatForm';
import ChatOptions from 'shared/components/ChatOptions';
import EmailInput from './template/EmailInput';

export default {
  name: 'AgentMessageBubble',
  components: {
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
  },
  mixins: [messageFormatterMixin],
  props: {
    message: String,
    contentType: String,
    messageType: Number,
    messageId: Number,
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  computed: {
    isTemplate() {
      return this.messageType === 3;
    },
    isTemplateEmail() {
      return this.contentType === 'input_email';
    },
    isCards() {
      return this.contentType === 'cards';
    },
    isOptions() {
      return this.contentType === 'input_select';
    },
    isForm() {
      return this.contentType === 'form';
    },
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-bubble {
  &.agent {
    background: $color-white;
    border-bottom-left-radius: $space-smaller;
    color: $color-body;
  }
}
</style>
