<script>
import { mapActions, mapGetters } from 'vuex';
import { useRouter } from 'vue-router';
import PreChatForm from '../components/PreChat/Form.vue';
import configMixin from '../mixins/configMixin';
import { ON_CONVERSATION_CREATED } from '../constants/widgetBusEvents';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: {
    PreChatForm,
  },
  mixins: [configMixin],
  setup() {
    const router = useRouter();
    return { router };
  },
  mounted() {
    // Register event listener for conversation creation
    emitter.on(ON_CONVERSATION_CREATED, this.handleConversationCreated);
  },
  beforeUnmount() {
    emitter.off(ON_CONVERSATION_CREATED, this.handleConversationCreated);
  },
  computed: {
    // starting a chat used to fail silently. The spinner stopped and
    // nothing else happened, so the customer had no message, no error and no way
    // to know a retry was worth attempting.
    ...mapGetters({ isCreateFailed: 'conversation/getIsCreateFailed' }),
  },
  methods: {
    ...mapActions('conversation', ['clearConversations']),
    ...mapActions('conversationAttributes', ['clearConversationAttributes']),
    handleConversationCreated() {
      // Redirect to messages page after conversation is created
      this.router.replace({ name: 'messages' });
      // Only after successful navigation, reset the isUpdatingRoute UIflag in app/javascript/widget/router.js
      // See issue: https://github.com/chatwoot/chatwoot/issues/10736
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
      // Contact custom attributes are sent within the same request that
      // identifies the contact. A separate update call would race the contact
      // merge on the server (matching email/phone) and write the values to
      // the destroyed contact, silently losing them.
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
            custom_attributes: contactCustomAttributes,
          },
        });
      } else {
        this.clearConversations();
        this.clearConversationAttributes();
        this.$store.dispatch('conversation/createConversation', {
          fullName: fullName,
          emailAddress: emailAddress,
          message: message,
          phoneNumber: phoneNumber,
          customAttributes: conversationCustomAttributes,
          contactCustomAttributes: contactCustomAttributes,
        });
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-1 flex-col overflow-auto">
    <div
      v-if="isCreateFailed"
      class="create-failed"
      role="alert"
      aria-live="assertive"
    >
      {{ $t('DELIVERY_PROBLEM.CREATE_FAILED') }}
    </div>
    <PreChatForm :options="preChatFormOptions" @submit-pre-chat="onSubmit" />
  </div>
</template>

<style scoped lang="scss">
.create-failed {
  background: var(--r-50, #fff1f0);
  border-radius: var(--space-smaller, 4px);
  color: var(--r-800, #8c1c13);
  font-size: var(--font-size-small, 0.875rem);
  margin: var(--space-small, 8px);
  padding: var(--space-small, 8px);
}
</style>
