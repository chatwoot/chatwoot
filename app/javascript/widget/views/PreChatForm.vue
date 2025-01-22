<script>
import PreChatForm from '../components/PreChat/Form.vue';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import { ON_CONVERSATION_CREATED } from '../constants/widgetBusEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin, routerMixin],
  mounted() {
    // Register event listener for conversation creation
    emitter.on(ON_CONVERSATION_CREATED, this.handleConversationCreated);
  },
  beforeUnmount() {
    emitter.off(ON_CONVERSATION_CREATED, this.handleConversationCreated);
  },
  methods: {
    async handleConversationCreated() {
      try {
        // Redirect to messages page after conversation is created
        await this.replaceRoute('messages');
        // Only after successful navigation, reset the isCreating UIflag
        // Added this to prevent creating multiple conversations
        // See issue: https://github.com/chatwoot/chatwoot/issues/10736
        await this.$store.dispatch(
          'conversation/setConversationIsCreating',
          false
        );
      } catch (error) {
        this.$store.dispatch('conversation/setConversationIsCreating', false);
      }
    },

    onSubmit({
      fullName,
      emailAddress,
      message,
      activeCampaignId,
      phoneNumber,
      contactCustomAttributes,
      conversationCustomAttributes,
    }) {
      if (activeCampaignId) {
        emitter.emit('execute-campaign', {
          campaignId: activeCampaignId,
          customAttributes: conversationCustomAttributes,
        });
        this.$store.dispatch('contacts/update', {
          user: {
            email: emailAddress,
            name: fullName,
            phone_number: phoneNumber,
          },
        });
      } else {
        this.$store.dispatch('conversation/createConversation', {
          fullName: fullName,
          emailAddress: emailAddress,
          message: message,
          phoneNumber: phoneNumber,
          customAttributes: conversationCustomAttributes,
        });
      }
      if (!isEmptyObject(contactCustomAttributes)) {
        this.$store.dispatch(
          'contacts/setCustomAttributes',
          contactCustomAttributes
        );
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-1 overflow-auto">
    <PreChatForm :options="preChatFormOptions" @submit-pre-chat="onSubmit" />
  </div>
</template>
