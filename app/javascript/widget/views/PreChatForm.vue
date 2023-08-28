<template>
  <div class="flex flex-1 overflow-auto">
    <pre-chat-form :options="preChatFormOptions" @submit="onSubmit" />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PreChatForm from '../components/PreChat/Form';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';
import { isEmptyObject } from 'widget/helpers/utils';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin, routerMixin],
  computed: {
    ...mapGetters({
      conversationSize: 'conversation/getConversationSize',
    }),
  },
  watch: {
    conversationSize(newSize, oldSize) {
      if (!oldSize && newSize > oldSize) {
        this.replaceRoute('messages');
      }
    },
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
        bus.$emit('execute-campaign', {
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
