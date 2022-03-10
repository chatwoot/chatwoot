<template>
  <div class="flex flex-1 overflow-auto">
    <pre-chat-form
      :options="preChatFormOptions"
      :disable-contact-fields="disableContactFields"
      @submit="onSubmit"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import PreChatForm from '../components/PreChat/Form';
import configMixin from '../mixins/configMixin';
import routerMixin from '../mixins/routerMixin';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin, routerMixin],
  computed: {
    ...mapGetters({
      conversationSize: 'conversation/getConversationSize',
    }),
    disableContactFields() {
      const { disableContactFields = false } = this.$route.params || {};
      return disableContactFields;
    },
  },
  watch: {
    conversationSize(newSize, oldSize) {
      if (!oldSize && newSize > oldSize) {
        this.replaceRoute('messages');
      }
    },
  },
  methods: {
    onSubmit({ fullName, emailAddress, message, activeCampaignId }) {
      if (activeCampaignId) {
        bus.$emit('execute-campaign', activeCampaignId);
        this.$store.dispatch('contacts/update', {
          user: {
            email: emailAddress,
            name: fullName,
          },
        });
      } else {
        this.$store.dispatch('conversation/createConversation', {
          fullName: fullName,
          emailAddress: emailAddress,
          message: message,
        });
      }
    },
  },
};
</script>
