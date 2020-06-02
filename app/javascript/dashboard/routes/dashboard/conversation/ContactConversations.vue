<template>
  <div class="contact-conversation--panel">
    <contact-details-item
      :title="$t('CONTACT_PANEL.CONVERSATIONS.TITLE')"
      icon="ion-chatboxes"
    />
    <div v-if="!uiFlags.isFetching">
      <p v-if="!previousConversations.length" class="no-results">
        {{ $t('CONTACT_PANEL.CONVERSATIONS.NO_RECORDS_FOUND') }}
      </p>
      <div v-else class="contact-conversation--list">
        <conversation-card
          v-for="conversation in previousConversations"
          :key="conversation.id"
          :chat="conversation"
          :hide-inbox-name="true"
          :hide-thumbnail="true"
          class="compact"
        />
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard.vue';
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import ContactDetailsItem from './ContactDetailsItem.vue';

export default {
  components: {
    ConversationCard,
    ContactDetailsItem,
    Spinner,
  },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
    conversationId: {
      type: [String, Number],
      required: true,
    },
  },
  computed: {
    conversations() {
      return this.$store.getters['contactConversations/getContactConversation'](
        this.contactId
      );
    },
    previousConversations() {
      return this.conversations.filter(
        conversation => conversation.id !== Number(this.conversationId)
      );
    },
    ...mapGetters({
      uiFlags: 'contactConversations/getUIFlags',
    }),
  },
  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.$store.dispatch('contactConversations/get', newContactId);
      }
    },
  },
  mounted() {
    this.$store.dispatch('contactConversations/get', this.contactId);
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

.contact-conversation--panel {
  padding: $space-normal;
}

.no-results {
  margin: 0;
  color: $color-gray;
}
</style>
