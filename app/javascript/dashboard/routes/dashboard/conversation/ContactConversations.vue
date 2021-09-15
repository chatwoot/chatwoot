<template>
  <div class="contact-conversation--panel">
    <div v-if="!uiFlags.isFetching" class="contact-conversation__wrap">
      <div v-if="!previousConversations.length" class="no-label-message">
        <span>
          {{ $t('CONTACT_PANEL.CONVERSATIONS.NO_RECORDS_FOUND') }}
        </span>
      </div>
      <div v-else class="contact-conversation--list">
        <conversation-card
          v-for="conversation in previousConversations"
          :key="conversation.id"
          :chat="conversation"
          :hide-inbox-name="false"
          :hide-thumbnail="true"
          class="compact"
        />
      </div>
    </div>
    <spinner v-else></spinner>
  </div>
</template>

<script>
import ConversationCard from 'dashboard/components/widgets/conversation/ConversationCard';
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';

export default {
  components: {
    ConversationCard,
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
.no-label-message {
  margin-bottom: var(--space-normal);
  color: var(--b-500);
}

.conv-details--item {
  padding-bottom: 0;
}
</style>
