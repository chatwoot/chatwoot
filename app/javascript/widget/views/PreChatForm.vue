<template>
  <div class="flex flex-1 overflow-auto">
    <pre-chat-form :options="preChatFormOptions" @submit="onSubmit" />
  </div>
</template>
<script>
import PreChatForm from '../components/PreChat/Form.vue';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';
import { isEmptyObject } from 'widget/helpers/utils';
import { ON_CONVERSATION_CREATED } from '../constants/widgetBusEvents';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin, routerMixin],
  mounted() {
    this.$emitter.on(ON_CONVERSATION_CREATED, () => {
      // Redirect to messages page after conversation is created
      this.replaceRoute('messages');
    });
  },
  methods: {
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
        this.$emitter.emit('execute-campaign', {
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
